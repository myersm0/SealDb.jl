
using ArgParse

s = ArgParseSettings()
@add_arg_table! s begin
	"program"
		required = true
		arg_type = Symbol
	"--project"
		arg_type = String
	"--patid"
		arg_type = String
	"--session"
		arg_type = String
	"--condition"
		arg_type = String
	"--series"
		arg_type = Int
	"--label"
		arg_type = String
	"--latest"
		arg_type = Bool
end

args = parse_args(ARGS, s)

