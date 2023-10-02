
using PythonCall
using Chain
using LinearAlgebra

st = pyimport("sentence_transformers")

model = st.SentenceTransformer("all-MiniLM-L6-v2")

query = "SELECT DISTINCT label FROM simple_outputs"
all_labels = exec_query(query)
embeddings = @chain model.encode(all_labels) pyconvert(Array, _)

cos_sim(a, b) = dot(a, b) / (norm(a) * norm(b))

test_query = "cross-realign 3D output"
test_embedding = @chain model.encode(test_query) pyconvert(Array, _)
scores = mapslices(x -> cos_sim(x, test_embedding), embeddings; dims = 2)






