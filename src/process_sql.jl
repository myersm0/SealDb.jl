
using Chain
using Dates

const PGHOME = "/data/sylvester/data1/users/myersm/postgresql-15.2"

function process_sql(query::String, dtype::Type)
	@chain begin
		read(`$PGHOME/bin/psql -d seal -qtAX -c $query`, String)
		split.(_, '\n')
		filter(x -> x .!= "", _)
		String.(_)
		if eltype(_) != dtype
			parse.(dtype, _)
		else
			_
		end
	end
end
export process_sql

function get_series(where_clause::String)::Vector{Int}
	query = "SELECT series FROM runs $where_clause ORDER BY series"
	process_sql(query, Int)
end
export get_series

function get_acq_times(where_clause::String)::Vector{Time}
	@chain begin
		"SELECT json->>'AcquisitionTime' FROM runs $where_clause ORDER BY series"
		process_sql(_, String)
		replace.(_, r"\..*" => "") # trim after decimal; don't need microsecond precision
		Time.(_, "H:M:S")
	end
end
export get_acq_times

function get_acq_time(session::String, series::Int)::Time
	where_clause = "WHERE session = '$session' AND series = $series"
	@chain begin
		"SELECT json->>'AcquisitionTime' FROM runs $where_clause"
		process_sql(_, String)
		replace.(_, r"\..*" => "") # trim str after decimal; don't need microsecond precision
		Time(_[1], "H:M:S")
	end
end
export get_acq_time

function get_functional_series(session::String; phase::Bool = false)
	where_clause = 
		"""
			WHERE session = '$session'
				AND quality != 'unusable'
				AND (json->>'SequenceName' LIKE 'epfid%' OR json->>'PulseSequenceName' LIKE 'epfid%')
				AND (NOT json ? 'ImageComments' OR NOT json->>'ImageComments' SIMILAR TO '%Single-band%reference%')
				AND $(phase ? "" : "NOT") json->'ImageType' ? 'PHASE'
		"""
	get_series(where_clause)
end
export get_functional_series

function get_fieldmap_series(session::String, ped::String)
	@assert(
		ped in ("j", "j-"),
		"Expected `ped` (phase encoding direction) to be j (for PA) or j- (for AP)"
	)
	where_clause =
		"""
			WHERE session = '$session'
				AND quality != 'unusable'
				AND (json->>'SequenceName' LIKE 'epse2d1%' OR json->>'PulseSequenceName' LIKE 'epse2d1%')
				AND json->>'PhaseEncodingDirection' = '$ped'
		"""
	get_series(where_clause)
end
export get_fieldmap_series

function get_structural_series(session::String, type::String)
	@assert(type in ("t1w", "t2w"), "Expected type to be `t1w` or `t2w`")
	pattern = 
		@match type begin
			"t2w" => "spcr?_314"
			"t1w" => "tfl3d1"
		end
	where_clause =
		"""
			WHERE session = '$session'
				AND quality = 'usable'
				AND json->>'SequenceName' ~* '$pattern'
				AND json->'ImageType' ? 'NORM'
		"""
	get_series(where_clause)
end
export get_structural_series

