\chapter{Pattern Let Floating}
\label{cha:plet-floating}

In this chapter we present our pattern let floating optimisation. In Section~\ref{sec:float_usage} we give usage instructions. In Section~\ref{sec:float_logical} we show a logical representation of the transformation. In Section~\ref{sec:float_implement} we provide some implementation details pertaining to the optimisation.
Lastly, in Section~\ref{sec:float_app} we apply pattern let floating to a sample program and examine the results.

\section{Usage}
\label{sec:float_usage}

We added the option:

\begin{verbatim}
--float-plet          float pattern lets to remove duplication
\end{verbatim}

to our Agda branch which, when enabled, will float the pattern lets up through the abstract syntax tree to join with other bindings for the same expression.

In combination with our option:
\begin{verbatim}
--cross-call-float          float pattern bindings across function calls
\end{verbatim}

bindings can also be shared across function calls.

We also added:

\begin{verbatim}
--abstract-plet       abstract pattern lets in generated code
\end{verbatim}
This splits generated function definitions into two functions,
the first containing only the top-level pattern bindings and a call to the second, and the second contining only the original body inside those pattern bindings, dependent on the additional variables bound in those patterns.

\section{Logical Representation}
\label{sec:float_logical}

\edcomm{WK}{Small separate examples missing \emph{here}.}

Pattern let floating combines the benefits of pattern lets, described in section~\ref{cha:logical_plet}, with the benefits of floating described in Section~\ref{sec:let_floating}. We take inspiration from \citet{jones1996}'s ``Full laziness'' transformation in GHC and apply it to the code generated by the Agda compiler backend. In our pattern let floating optimisation, we float the pattern let as far upwards in an expression tree if and until they can be joined with another floated pattern let on the same variable.  By doing so, we avoid re-computing the same expression when it is used in multiple subexpressions.

\section{Implementation}
\label{sec:float_implement}

There are a couple of implementation-specific details of interest when implementing pattern let floating. Firstly, in order to float pattern lets, we first convert the |TTerm|s into a variant data type using named variables for ease of expression manipulation. Then the entire expression tree is recursed over, floating all $\lambda$ bindings to the top of the expression and accumulating a list of variables in each definition is accumulated.

The |floatPatterns| function will only float pattern lets which occur in multiple branches, and they are floated to the least join point of those branches.

Further, it is worth noting that pattern let occurrences are duplicated at join points, indicating that identical \edcomm{WK}{only the RHS needs to be ``identical'' (up to $\alpha$-conversion); the patterns are unified. E.g., |let a@(b@(c,d),e) = RHS| and |let a@(b, c@(d,e)) = RHS| are unified into |let f@(g@(h,i),j@(k,l)) = RHS|. (Note that these |let| bindings are non-recursive!)} pattern lets have ``met'' there, and are then later simplified away with the |squashFloatings| function.

We are further expanding the pattern let floating optimisation such that they can not only be floated up expressions, but also across function calls. By floating pattern lets across function calls, we can avoid even more duplicated computation through sharing.

This feature is implemented by splitting the pattern lets at the root of functions into separate pattern lets and a body. By creating secondary functions that take the variables bound by pattern lets and make them explicit arguments to a separate function, we can abstract the patterns across function calls.

\section{Application}
\label{sec:float_app}

\subsection*{Triangle}

As readers may have noticed inspecting Figure~\ref{fig:Triangle_genplet} in the preceding chapter, there are 4 pattern let bindings for the same \texttt{v2} variable within the \texttt{d4788} function. This is a perfect opportunity for floating pattern lets, to create sharing where there formerly was none.

\begin{figure}[h]
\centering
\lstinputlisting[style=diff]{Figures/Triangle_float.diff}
\caption{Unified difference of the \AgdaModule{Triangle3sPB}~module compiled without and then with @--float-plet@.}
\label{fig:Triangle_float}
\end{figure}

Figure~\ref{fig:Triangle_float} shows the result of applying @--float-plet@ to this compilation, resulting in the \texttt{v2} bindings floating above the shared function call.

\subsection*{Pullback}

\edcomm{NP}{Write words here}

\begin{figure}[h]
\centering
\lstinputlisting[style=diff]{Figures/Pullback_float.diff}
\caption{Unified difference of the \AgdaModule{Pullback}~module compiled without and then with @--float-plet@.}
\label{fig:Triangle_float}
\end{figure}

\begin{figure}[h]
\centering
\lstinputlisting[style=diff]{Figures/Pullback_crosscall.diff}
\caption{Unified difference of the \AgdaModule{Pullback}~module compiled without and then with @--cross-call-float@.}
\label{fig:Triangle_crosscall}
\end{figure}
