\documentclass{beamer}

\usetheme{Boadilla}
\usecolortheme{whale}

\AtBeginSection[]{
  \begin{frame}
  \vfill
  \centering
  \begin{beamercolorbox}[sep=8pt,center,shadow=true,rounded=true]{title}
    \usebeamerfont{title}\insertsectionhead\par%
  \end{beamercolorbox}
  \vfill
  \end{frame}
}

\makeatother
\setbeamertemplate{footline}
{
  \leavevmode%
  \hbox{%
  \begin{beamercolorbox}[wd=.35\paperwidth,ht=2.25ex,dp=1ex,center]{author in head/foot}%
    \usebeamerfont{author in head/foot}\insertshortauthor
  \end{beamercolorbox}%
  \begin{beamercolorbox}[wd=.65\paperwidth,ht=2.25ex,dp=1ex,center]{title in head/foot}%
    \usebeamerfont{title in head/foot}\insertshorttitle\hspace*{3em}
    \insertframenumber{} / \inserttotalframenumber\hspace*{1ex}
  \end{beamercolorbox}}%
  \vskip0pt%
}
\makeatletter
\setbeamertemplate{navigation symbols}{}

%include polycode.fmt
\usepackage[round]{natbib}
\usepackage{comment}
\usepackage{../Styles/agda}
\usepackage{../Styles/AgdaChars}
\usepackage{tikz}
\usetikzlibrary{shapes,positioning,arrows.meta}
\usepackage{subcaption}
\usepackage{listings}

\newcommand{\lstbg}[3][0pt]{{\fboxsep#1\colorbox{#2}{\strut #3}}}
\lstdefinelanguage{diff}{
  morecomment=[f][\lstbg{red!20}]-,         % deleted lines
  morecomment=[f][\lstbg{green!20}]+,       % added lines
  morecomment=[f][\textit]{---}, % header lines
  morecomment=[f][\textit]{+++}
}
\lstdefinestyle{diff}{
	language=diff,
	basicstyle=\ttfamily\footnotesize
}

\title{(Re-)Creating sharing in Agda's GHC backend}
\author{Natalie Perna}

\institute{
  Department of Computing and Software\\
  McMaster University
}

\date{Tuesday, June 6, 2017}

\begin{document}

\begin{frame}
\titlepage
\end{frame}

\begin{frame}{Outline}
\tableofcontents
\end{frame}

\section{Agda}

\begin{frame}{Agda}
Agda \citep{Norell-2007} is a dependently-typed programming language and theorem prover, supporting proof construction in a functional programming style.
\end{frame}

\begin{frame}{Example}
\input{Agda/latex/Replicate}
\end{frame}

\begin{frame}{Syntax}
Agda supports flexible mixfix syntax and Unicode \citep{bove2009}.
\input{Agda/latex/If}
\end{frame}

\begin{frame}{Readability}
Fine-grain control over proof syntax allows for readable formats.
\input{Agda/latex/Proof}
\end{frame}

\section{Compiler}

\begin{frame}{GHC Backend}
\textit{Goal}: Achieve performance matching GHC.\\
\textit{Solution}: Translate Agda into Haskell, compile with GHC.\\
\citep{benke2007}
\end{frame}

\begin{frame}{Performance}
Good performance, but additional passes over generated code necessary to harness GHC's strengths and avoid its pitfalls, namely due to the lack of GHC optimisations that occur around unsafe coercions \citep{fredriksson2011}.
\end{frame}

\begin{frame}{Stages of compilation}
\input{Figures/CompilerFlowchart}
\end{frame}

\section{Optimisations}

\subsection{Projection Inlining}

\begin{frame}{Projection Inlining}

Inline all proper projections.

\begin{itemize}
  \item Recurse through expression tree
  \item Identify proper projections by qualified name
  \item Replace function with body
  \item Substitute in function arguments
\end{itemize}
\end{frame}

\begin{frame}{Projection Inlining: Application}
\input{Agda/latex/Example1}
\end{frame}

\begin{frame}{Projection Inlining: Application}
\lstinputlisting[style=diff]{Figures/Example1_inline.diff}
\end{frame}

\subsection{Case Squashing}

\begin{frame}{Case Squashing}

Eliminate case expressions where the scrutinee has already been matched on by an enclosing ancestor case expression.

\begin{figure}[h]
\footnotesize
\centering
\begin{subfigure}{.47\textwidth}
\centering
\begin{spec}
case x of
  d v0..vn ->
    ...
      case x of
        d v0'...vn' -> r
\end{spec}
\end{subfigure}
{$\longrightarrow$}
\begin{subfigure}{.47\textwidth}
\centering
\begin{spec}
case x of
  d v0...vn ->
    ...
      r[v0' := v0, ..., vn' := vn]
\end{spec}
\end{subfigure}
\end{figure}
\end{frame}

\begin{frame}{Case Squashing: Application}
\lstinputlisting[style=diff]{Figures/Example1_squash.diff}
\end{frame}

\subsection{Pattern Let Generating}

\begin{frame}{Pattern Let Generating}
We can avoid generating certain trivial case expressions by identifying qualifying let expressions.

\begin{figure}[h]
\footnotesize
\centering
\begin{subfigure}{.47\textwidth}
\begin{spec}
let x = e
in case x of
  d v0...vn -> t
  otherwise -> u
\end{spec}
where |unreachable(u) == true|.
\end{subfigure}
{$\longrightarrow$}
\begin{subfigure}{.47\textwidth}
\begin{spec}
let x@(d v0...vn) = e
in t
\end{spec}
\end{subfigure}
\end{figure}
\end{frame}

\begin{frame}{Pattern Let Generating: Application}
TODO
\end{frame}

\subsection{Pattern Let Floating}

\begin{frame}{Pattern Let Floating}
Float pattern lets up through the abstract syntax tree to join with other bindings for the same expression.

\begin{figure}[h]
\footnotesize
\centering
\begin{subfigure}{.47\textwidth}
\begin{spec}
f  (let x@(d v0...vn) =  e in t1)
   (let x@(d v0...vn) =  e in t2)
\end{spec}
\end{subfigure}
{$\longrightarrow$}
\begin{subfigure}{.47\textwidth}
\begin{spec}
let x@(d v0...vn) = e
in f t1 t2
\end{spec}
\end{subfigure}
\end{figure}
TODO
\end{frame}

\begin{frame}{Pattern Let Floating: Application}
TODO
\end{frame}

\section{Conclusion}

\begin{frame}{Conclusion}
TODO
\end{frame}

\section{References}

\begin{frame}{Bibliography}
\bibliographystyle{plainnat}
\bibliography{../Bibliography/RATH/strings,../Bibliography/RATH/ref,../Bibliography/RATH/crossrefs,../Bibliography/ref}
\end{frame}

\section*{Questions}

\end{document}
