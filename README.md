# reproducible-workflows-example

An example of a reproducible workflow based in `R` and using RStudio
(for self-contained project management) and GitHub (for version control).

[global.md]() is both the "controller" script of the workflow and a tutorial.
Other sourced `R` scripts and functions are contained in the `/codes` folder.

This workflow relies heavily on the `R` packages:
- [`Require`](https://require.predictiveecology.org/) - for self-contained and reproducible `R` package installation;

- [`reproducible`](https://reproducible.predictiveecology.org/) - for caching, data sourcing, common GIS operations, and more.

Other `R` packages can be used in their place, however, and this workflow 
should be regarded as one of *many* ways in which reproducible workflows
can be built in `R`.