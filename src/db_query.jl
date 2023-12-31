
function exec_query(query::String)::Vector{String}
	@chain begin
		read(`psql -d seal -qtAX -c "$query"`, String)
		split.(_, '\n')
		filter(x -> x .!= "", _)
	end
end

# helper for mapping the Dict of command-line args to fn args
check_key(d::Dict, k::Symbol)::Bool = haskey(d, k) && !isnothing(d[k])

function defined_keys(d::Dict; relevant::Union{Nothing, Vector{Symbol}} = nothing)::Set
	ks = filter(k -> !isnothing(d[k]), keys(d))
	if !isnothing(relevant)
		irrelevant = setdiff(ks, relevant)
		if length(irrelevant) > 0
			@warn "Ignoring irrelevant arguments $irrelevant"
			setdiff!(ks, irrelevant)
		end
	end
	ks
end

function get_functional_runs(d::Dict)::Vector{Int}
	ks = defined_keys(d; relevant = [:session, :protocol])
	if ks == Set([:session])
		query = "SELECT * FROM get_functional_runs('$(d[:session])')"
	elseif Set([:session, :protocol])
		query = "SELECT * FROM get_functional_runs('$(d[:session])', '$(d[:protocol])')"
	end
	@chain begin
		exec_query(query)
		parse.(Int, _)
		sort
	end
end
get_functional_runs(; kwargs...) = get_functional_runs(Dict(kwargs))

function get_functional_run_metadata(d::Dict)::OrderedDict{Int, Dict{String, Any}}
	ks = defined_keys(d; relevant = [:session, :series])
	if ks == Set([:session])
		query = "SELECT * FROM get_functional_run_metadata('$(d[:session])')"
	elseif ks == Set([:session, :series])
		query = "SELECT * FROM get_functional_run_metadata('$(d[:session])', $(d[:series]))"
	end
	@chain begin
		exec_query(query)
		split.(_, '|')
		OrderedDict([parse(Int, x[1]) => JSON.parse(x[2]) for x in _])
	end
end
get_functional_run_metadata(; kwargs...) = get_functional_run_metadata(Dict(kwargs))

function get_paths(d::Dict)
	ks = defined_keys(d; relevant = [:session, :label, :series])
	if ks == Set([:session])
		query = "SELECT * FROM get_latest_paths('$(d[:session])')"
	elseif ks == Set([:session, :label])
		query = "SELECT * FROM get_latest_paths('$(d[:session])', '$(d[:label])')"
	elseif ks == Set([:session, :label, :series])
		query = "SELECT * FROM get_latest_path('$(d[:session])', $(d[:series]), '$(d[:label])')"
	end
	exec_query(query)
end
get_paths(; kwargs...) = get_paths(Dict(kwargs))

function get_sessions(d::Dict)::Vector{String}
	ks = defined_keys(d; relevant = [:patid, :condition, :project])
	where_clause = "WHERE patid = '$(d[:patid])'"
	if check_key(d, :condition)
		where_clause *= " AND condition = '$(d[:condition])'"
	end
	if check_key(d, :project)
		where_clause *= " AND project = '$(d[:project])'"
	end
	query = "SELECT session FROM sessions $where_clause ORDER BY date"
	exec_query(query)
end
get_sessions(; kwargs...) = get_sessions(Dict(kwargs))


