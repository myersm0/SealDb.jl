
function process_sql(query::String, dtype::Type)
	@chain begin
		read(`psql -d $dbname -qtAXc $query`, String)
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

function get_series(where_clause::String)::Vector{Int}
	query = "SELECT series FROM runs $where_clause ORDER BY series"
	process_sql(query, Int)
end

function get_acq_times(where_clause::String)::Vector{Time}
	@chain begin
		"SELECT json->>'AcquisitionTime' FROM runs $where_clause ORDER BY series"
		process_sql(_, String)
		replace.(_, r"\..*" => "") # trim after decimal; don't need microsecond precision
		Time.(_, "H:M:S")
	end
end

function get_acq_time(session::String, series::Int)::Time
	where_clause = "WHERE session = '$session' AND series = $series"
	@chain begin
		"SELECT json->>'AcquisitionTime' FROM runs $where_clause"
		process_sql(_, String)
		replace.(_, r"\..*" => "") # trim str after decimal; don't need microsecond precision
		Time(_[1], "H:M:S")
	end
end

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

function get_structural_series(session::String, type::String; vnavs::Bool = false)
	@assert(type in ("t1w", "t2w"), "Expected type to be `t1w` or `t2w`")
	pattern = 
		@match type begin
			"t2w" => vnavs ? "spcr?_200" : "spcr?_314"
			"t1w" => vnavs ? "tfl_me3d1" : "tfl3d1"
		end
	where_clause =
		"""
			WHERE session = '$session'
				AND quality = 'usable'
				AND json->>'$(vnavs ? "PulseSequenceName" : "SequenceName")' ~* '$pattern'
				AND json->'$(vnavs ? "ImageTypeText" : "ImageType")' ? 'NORM'
		"""
	get_series(where_clause)
end

