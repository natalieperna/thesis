\chapter{Pattern Let Floating}
\label{cha:plet-floating}

\section{Usage}

We added the options:

\begin{verbatim}
--float-plet                                float pattern lets to remove duplication
\end{verbatim}

to our Agda branch which, when enabled, will float the pattern lets up through the abstract syntax tree to join with other bindings for the same expression.

\section{Logical Representation}

Pattern let floating combines the benefits of pattern lets, described in section~\ref{cha:logical_plet}, with the benefits of floating described in Section~\ref{sec:let_floating}. We take inspiration from \citet{jones1996}'s ``Full laziness'' transformation in GHC and apply it to the code generated by the Agda compiler backend. In our pattern let floating optimisation, we float the pattern let as far upwards in an expression tree if and until they can be joined with another floated pattern let on the same variable.  By doing so, we avoid re-computing the same expression when it is used in multiple subexpressions.

\section{Implementation}

There are a couple of implementation-specific details of interest when implementing pattern let floating. Firstly, the |floatPLet| function will only float pattern lets which occur in multiple branches, and they are floated to the least join point of those branches.

Further, it is worth noting that pattern let occurrences are duplicated at join points, indicating that identical pattern lets have ``met'' there, and are then later simplified away with the |squashFloatings| function.

\section{Application}

As readers may have noticed inspecting Figure~\ref{fig:Triangle_genplet} in the preceding chapter, there are 4 pattern let bindings for the same \texttt{v2} variable within the \texttt{d4788} function. This is a perfect opportunity for floating pattern lets, to create sharing where there formerly was none.

\begin{figure}[h]
    \centering
    \lstinputlisting[style=diff]{Figures/Triangle_float.diff}
    \caption{Unified difference of the \AgdaModule{Triangle3sPB}~module compiled without and then with @--float-plet@.}
    \label{fig:Triangle_float}
\end{figure}

Figure~\ref{fig:Triangle_float} shows the result of applying @--float-plet@ to this compilation, resulting in the \texttt{v2} bindings floating above the shared function call.

\section{Next Steps}

Our goal is to further expand the pattern let floating optimisation such that they can not only be floated up expressions, but also across function calls. By floating pattern lets across function calls, we can avoid even more duplicated computation through sharing.
