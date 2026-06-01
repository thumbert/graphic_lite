# graphic_lite

A high level graphics library for Flutter with a Plotly JS like API.

**NOTE** This is a work very much in progress.  While I ported a type-safe 
API based on Plotly JS, most/all of the underlying implementation is done 
by Claude using the the excellent [graphic](https://pub.dev/packages/graphic) package.  I'm going one detail at a time, to keep the requests relatively 
focused.  It is my first project where I'm trying to do this kind of 
development, so I'm curious how far it is possible to advance the project, 
and how difficult maintenance will become in the future. 

See currently working examples here: [https://polywatt.pages.dev/graphic-lite/](https://polywatt.pages.dev/graphic-lite/) 

## Motivation and Goals
As of 2026, there are few Flutter packages for data visualization.  Outside of Dart/Flutter ecosystem, there is a large variety of high quality open-source choices, see for example the venerable [gnuplot](http://www.gnuplot.info/), the [R project](https://www.r-project.org/), a plethora of Python choices, for example [matplotlib](https://matplotlib.org/) and then JS options 
[Plotly](https://plotly.com/javascript/), [vega](https://vega.github.io/vega/), 
[ECharts](https://echarts.apache.org/), etc.   It would be impossible to list and do justice to all. 

Implementing a comprehensive, extensible, performant and coherent graphics library is not an easy task.  Because Dart/Flutter can interface easily with Java Script there has always been the option to use a mature Java Script library and call it a day.  But as Dart/Flutter gains a wider adoption, it makes sense to have a native visualization library available for all targets. 







