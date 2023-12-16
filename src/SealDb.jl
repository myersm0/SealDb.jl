
module SealDb

using Chain
using Dates
using JSON
using Match
using OrderedCollections

const dbname = "seal"
const hostname = read(`hostname`, String) |> chomp

include("db_query.jl")

include("process_sql.jl")
export process_sql, get_series, get_acq_times, get_acq_time
export get_functional_series, get_fieldmap_series, get_structural_series

end



