from __future__ import annotations

import html
import math
from datetime import timedelta
from pathlib import Path
from typing import Any


class ReportFailure(RuntimeError):
    pass


def validate_thresholds(threshold_abs: float, threshold_rel: float) -> None:
    if any(not math.isfinite(value) or value < 0 for value in (threshold_abs, threshold_rel)):
        raise ValueError("Error thresholds must be finite and non-negative")


def select_catchments(
    expected: Any,
    actual: Any,
    catchment_count: int,
    threshold_abs: float,
    threshold_rel: float,
) -> list[int]:
    validate_thresholds(threshold_abs, threshold_rel)
    maximum_absolute = [0.0] * catchment_count
    maximum_relative = [0.0] * catchment_count
    for index, (expected_value, actual_value) in enumerate(zip(expected, actual)):
        catchment = index % catchment_count
        absolute_error = abs(actual_value - expected_value)
        relative_error = absolute_error / max(abs(expected_value), abs(actual_value), 1.0e-30)
        maximum_absolute[catchment] = max(maximum_absolute[catchment], absolute_error)
        maximum_relative[catchment] = max(maximum_relative[catchment], relative_error)
    return [
        catchment + 1
        for catchment, (absolute_error, relative_error) in enumerate(zip(maximum_absolute, maximum_relative))
        if absolute_error >= threshold_abs or relative_error >= threshold_rel
    ]


def write_report(
    results_dir: Path,
    manifest: dict[str, Any],
    shape: dict[str, Any],
    results: dict[str, dict[str, Any]],
    errors: list[str],
    threshold_abs: float,
    threshold_rel: float,
) -> Path:
    try:
        import plotly.graph_objects as go
        from plotly.subplots import make_subplots
    except ImportError as exc:
        raise ReportFailure(
            "Interactive reports require the optional dependency: "
            "python -m pip install -r requirements-report.txt"
        ) from exc

    validate_thresholds(threshold_abs, threshold_rel)
    metadata = (
        f"{manifest['simulation_start']} to {manifest['simulation_end']}; "
        f"{shape['timestep_seconds']} second steps; {shape['catchment_count']} catchments"
    )
    page = [
        "<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\">",
        "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
        f"<title>{html.escape(manifest.get('case_name', 'Regression report'))}</title>",
        "<style>body{font:16px system-ui,sans-serif;max-width:1200px;margin:2rem auto;padding:0 1rem;color:#17212b}"
        "table{border-collapse:collapse;width:100%;font-size:.9rem}th,td{border:1px solid #ccd3da;padding:.45rem;text-align:left}"
        "th{background:#eef2f5}section{margin:2rem 0}pre{white-space:pre-wrap;background:#f5f6f7;padding:1rem}"
        ".fail{color:#a00;font-weight:700}.pass{color:#176b35;font-weight:700}</style></head><body>",
        f"<h1>{html.escape(manifest.get('case_name', 'Regression report'))}</h1>",
        f"<p>{html.escape(manifest.get('description', ''))}</p><p>{html.escape(metadata)}</p>",
        f"<p>Catchment thresholds: absolute ≥ {threshold_abs:g} or relative ≥ {threshold_rel:g}. "
        "Thresholds select plots and do not change regression acceptance.</p>",
        "<h2>Comparison results</h2>",
        "<p>p99 uses linear interpolation at sorted position 0.99 × (n − 1). "
        "Relative error is |actual − expected| / max(|expected|, |actual|, 1e−30). "
        "A value passes when |actual − expected| ≤ atol and relative error ≤ rtol.</p>",
        "<table><thead><tr><th>Output</th><th>dtype / count</th><th>p99 / max absolute error</th>"
        "<th>p99 / max relative error</th><th>Maximum locations</th><th>Tolerance / result</th>"
        "</tr></thead><tbody>",
    ]

    for path, result in results.items():
        status = "PASS" if result["passed"] else "FAIL"
        status_class = "pass" if result["passed"] else "fail"
        max_abs_location = result["max_abs_location"]
        max_rel_location = result["max_rel_location"]
        abs_location = (
            f"index {max_abs_location['index']}, timestep {max_abs_location['timestep']}, "
            f"{max_abs_location['date']}, catchment {max_abs_location['catchment']}"
            if max_abs_location else "n/a"
        )
        rel_location = (
            f"index {max_rel_location['index']}, timestep {max_rel_location['timestep']}, "
            f"{max_rel_location['date']}, catchment {max_rel_location['catchment']}"
            if max_rel_location else "n/a"
        )
        page.append(
            "<tr>"
            f"<td>{html.escape(path)} ({html.escape(result['unit'])})</td>"
            f"<td>{html.escape(result['dtype'])} / {result['count']}</td>"
            f"<td>{result['p99_abs']:.8e} / {result['max_abs']:.8e}</td>"
            f"<td>{result['p99_rel']:.8e} / {result['max_rel']:.8e}</td>"
            f"<td>absolute: {html.escape(abs_location)}<br>relative: {html.escape(rel_location)}</td>"
            f"<td>atol={result['atol']:.8e}; rtol={result['rtol']:.8e}; "
            f"outside={result['outside_tolerance']} <span class=\"{status_class}\">{status}</span></td>"
            "</tr>"
        )
    page.append("</tbody></table>")

    if errors:
        page.extend(("<h2>Comparison errors</h2><pre>", html.escape("\n".join(errors)), "</pre>"))

    charts = [
        "<h2>Hydrographs</h2><p>Each output shows catchments whose maximum absolute or relative "
        "error over the simulation meets its threshold.</p>"
    ]
    plotly_included = False
    selected_any = False
    for path, result in results.items():
        if not result["count"]:
            continue
        selected = select_catchments(
            result["expected_values"], result["actual_values"], result["catchment_count"],
            threshold_abs, threshold_rel,
        )
        charts.append(f"<section><h3>{html.escape(path)}</h3>")
        if not selected:
            charts.append("<p>No catchments meet the thresholds for this output.</p></section>")
            continue
        selected_any = True
        charts.append(f"<p>Selected catchments: {', '.join(map(str, selected))}</p>")
        start = shape["simulation_start"]
        dates = [
            (start + timedelta(seconds=index * shape["timestep_seconds"])).isoformat(sep=" ")
            for index in range(result["timestep_count"])
        ]
        unit = result["unit"] or "value"
        for catchment in selected:
            indices = range(catchment - 1, result["count"], result["catchment_count"])
            expected = [result["expected_values"][index] for index in indices]
            indices = range(catchment - 1, result["count"], result["catchment_count"])
            actual = [result["actual_values"][index] for index in indices]
            residual = [actual_value - expected_value for expected_value, actual_value in zip(expected, actual)]

            figure = make_subplots(rows=2, cols=1, shared_xaxes=True, vertical_spacing=0.12)
            figure.add_trace(go.Scatter(x=dates, y=expected, mode="lines", name="Expected"), row=1, col=1)
            figure.add_trace(go.Scatter(x=dates, y=actual, mode="lines", name="Actual"), row=1, col=1)
            figure.add_trace(go.Scatter(x=dates, y=residual, mode="lines", name="Residual"), row=2, col=1)
            figure.update_yaxes(title_text=f"Value ({unit})", row=1, col=1)
            figure.update_yaxes(title_text=f"Residual ({unit})", row=2, col=1)
            figure.update_xaxes(title_text="Date", row=2, col=1)
            figure.update_layout(
                title=f"Catchment {catchment}",
                template="plotly_white",
                height=620,
                legend={"orientation": "h", "y": 1.1},
                margin={"t": 80, "b": 55},
            )
            charts.append(
                figure.to_html(full_html=False, include_plotlyjs=not plotly_included, config={"responsive": True})
            )
            plotly_included = True
        charts.append("</section>")

    if not selected_any:
        charts.append("<p>No catchments meet the report thresholds.</p>")
    page.extend(charts)
    page.append("</body></html>")
    report_path = results_dir / "report.html"
    report_path.write_text("\n".join(page), encoding="utf-8")
    return report_path
