% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/io.R
\name{write_ghgv}
\alias{write_ghgv}
\title{Writes a json string to a json or csv file.}
\usage{
write_ghgv(json, output_dir, filename = "ghgv", format = c("json", "csv"))
}
\arguments{
\item{json}{a json object of the ghgv output.}

\item{output_dir}{the directory to write the data to.}

\item{filename}{(character) name of file to write.}

\item{format}{(character) file format to write.}
}
\value{
TRUE if written with no errors.
}
\description{
Writes a json string to a json or csv file.
}

