using Documenter, GasModels

makedocs(
    modules = [GasModels],
    format = Documenter.HTML(analytics = "UA-367975-10", mathengine = Documenter.MathJax()),
    sitename = "GasModels",
    authors = "Russell Bent and contributors.",
    pages = [
        "Home" => "index.md",
        "Manual" => [
            "Getting Started" => "quickguide.md",
            "Input Data Formats" => "data-format.md",
            "Result Data Format" => "result-data.md",
            "Mathematical Model" => "math-model.md"
        ],
        "Library" => [
            "Network Formulations" => "formulations.md",
            "Problem Specifications" => "specifications.md",
            "Modeling Components" => [
                "GasModel" => "model.md",
                "Objective" => "objective.md",
                "Variables" => "variables.md",
                "Constraints" => "constraints.md"
            ],
            "File IO" => "parser.md"
        ],
        "Developer" => "developer.md"
    ]
)

deploydocs(
    repo = "github.com/lanl-ansi/GasModels.jl.git",
)
