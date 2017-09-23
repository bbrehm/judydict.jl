using DataStructures
include("./judydict.jl")

Nm=1000*1000
test_keys = Vector{Int64}(Nm)
test_vals = Vector{Int64}(Nm)
test_keys2 = Vector{Int64}(Nm)
for i in 1:Nm
    test_keys[i] = rand(1:2^60)
    test_keys2[i] = rand(1:2^60)  
    test_vals[i] = rand(1:2^60)                
end


function store_test(sd, keys_,vals_)
    for i in 1:length(keys_)
        sd[keys_[i]]=vals_[i]
    end
    return nothing
end
    
function read_test(sd,keys_,vals_) 
    sum::Int64 = 0
    for i in 1:length(keys_)
        sdv = sd[keys_[i]]
        assert(sdv == vals_[i])
    end
    return sum
end
    
function del_test(sd,keys_) 
    for i in 1:length(keys_)
            delete!(sd, keys_[i])
    end
    return nothing
end

function findnext_test(sd::SortedDict,keys_) 
    for i in 1:length(keys_)
             searchsortedfirst(sd,keys_[i])
    end
    return nothing
end

function findnext_test(sd::judydict.JudyDict,keys_) 
    for i in 1:length(keys_)
            judydict.ju_next(sd,keys_[i])
    end
    return nothing
end

function iter_test(sd::SortedDict, keys_) 
    idx::Int64 = 0
    num_iter = 0
    for (key_, value_) in sd
        num_iter += 1
    end
    assert(num_iter == length(keys_))
    return num_iter
end
    
function iter_test(jd::judydict.JudyDict,keys_) 
    idx::Int64 = 0
    num_iter = 0
    vptr:: Ptr{Int}=C_NULL
    (idx, vptr) = judydict.ju_next_inclusive(jd, idx)
    while vptr != C_NULL
        (idx, vptr) = judydict.ju_next(jd, idx)
        num_iter +=1
    end
    assert(num_iter == length(keys_))    
    return num_iter
end

function iter_test(usd::Dict,keys_) 
    idx::Int64 = 0
    num_iter = 0
    for (key_, value_) in usd
        num_iter += 1
    end
    assert(num_iter == length(keys_))
    return num_iter
end
#######################################
println("Trivial benchmark with ", Nm, " elements")

sd = SortedDict{Int64, Int64}()
store_test(sd, test_keys, test_vals)
read_test(sd, test_keys, test_vals)
findnext_test(sd, test_keys2)
iter_test(sd, test_keys)
del_test(sd, test_keys)
sd = 0

gc()
println("Timings for SortedDict{Int64,Int64}, setindex!, getindex, findnext, iterate, delete!")
sd = SortedDict{Int64, Int64}()
@time store_test(sd, test_keys, test_vals)
@time read_test(sd, test_keys, test_vals)
@time findnext_test(sd, test_keys2)
@time iter_test(sd, test_keys)
@time del_test(sd, test_keys)
sd = 0

gc()
println("Timings for SortedDict{Int64,Int64}, setindex!, getindex, findnext, iterate, delete!")
sd = SortedDict{Int64, Int64}()
@time store_test(sd, test_keys, test_vals)
@time read_test(sd, test_keys, test_vals)
@time findnext_test(sd, test_keys2)
@time iter_test(sd, test_keys)
@time del_test(sd, test_keys)
sd = 0

#######################################

jd = judydict.JudyDict()
store_test(jd, test_keys, test_vals)
read_test(jd, test_keys, test_vals)
mem_used = judydict.ju_mem_used(jd)
findnext_test(jd, test_keys2)
iter_test(jd, test_keys)
del_test(jd, test_keys)
jd = 0



gc()
println("Timings for judydict, setindex!, getindex, findnext, iterate, delete!")
jd = judydict.JudyDict()
@time store_test(jd, test_keys, test_vals)
@time read_test(jd, test_keys, test_vals)
mem_used = judydict.ju_mem_used(jd)
@time findnext_test(jd, test_keys2)
@time iter_test(jd, test_keys)
@time del_test(jd, test_keys)
println("reported memory usage: ", mem_used)
jd = 0

gc()
println("Timings for judydict, setindex!, getindex, findnext, iterate, delete!")
jd = judydict.JudyDict()
@time store_test(jd, test_keys, test_vals)
@time read_test(jd, test_keys, test_vals)
mem_used = judydict.ju_mem_used(jd)
@time findnext_test(jd, test_keys2)
@time iter_test(jd, test_keys)
@time del_test(jd, test_keys)
println("reported memory usage: ", mem_used)
jd = 0

#######################################
usd = Dict{Int64, Int64}()
store_test(usd, test_keys, test_vals)
read_test(usd, test_keys, test_vals)
iter_test(usd, test_keys)
del_test(usd, test_keys)
usd = 0

gc()
println("Timings for Dict{Int64,Int64}, setindex!, getindex, iterate, delete!")
usd = Dict{Int64, Int64}()
@time store_test(usd, test_keys, test_vals)
@time read_test(usd, test_keys, test_vals)
@time iter_test(usd, test_keys)
@time del_test(usd, test_keys)
gc()

gc()
println("Timings for Dict{Int64,Int64}, setindex!, getindex, iterate, delete!")
usd = Dict{Int64, Int64}()
@time store_test(usd, test_keys, test_vals)
@time read_test(usd, test_keys, test_vals)
@time iter_test(usd, test_keys)
@time del_test(usd, test_keys)
gc()



