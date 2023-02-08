export TerminationStatus, SolutionStatus


"""
Termination status
"""
@enum(TerminationStatus,
    Trm_NotCalled,
    Trm_Unknown,
    # OK statuses
    Trm_Optimal,
    Trm_PrimalInfeasible,
    Trm_DualInfeasible,
    Trm_PrimalDualInfeasible,
    Trm_Feasibility,
    Trm_Infeasibility,
    # Limits
    Trm_IterationLimit,
    Trm_TimeLimit,
    # Errors
    Trm_MemoryLimit,
    Trm_NumericalProblem,
    # Others
    Trm_SolverUsed
)


"""
SolutionStatus
"""
@enum(SolutionStatus,
    Sln_Unknown,
    Sln_Optimal,
    Sln_FeasiblePoint,
    Sln_Infeasible,
    Sln_InfeasiblePoint,
    Sln_InfeasibilityCertificate,
    Sln_SolverUsed
)