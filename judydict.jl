module judydict

    import  Base.getindex,
            Base.setindex!,
            Base.delete!

    const _judylib = "libJudy"

    #JudyDict stores a sorted map UInt64-> 8 bytes. 
    # You can probably get judy by your analogue of apt-get install judy.
    #I implemented the interface as a map Int64->Int64, so make sure that the 
    #first bit of keys is not set, otherwise your sort order will be wrong. 
    #canonically, you will store pointers in the value.
    #If you can write a nice interface for UInt64 which issues no extra instructions, please do! 
    #I failed at getting rid of all emitted checks for the top bit, but I am new to julia.
    type JudyDict
        jd::Ptr{Void}
        jdi::Int
        jd_ptr::Ptr{Ptr{Void}}
        jdi_ptr::Ptr{Int}
        function JudyDict()
            j = new()
            j.jd = C_NULL 
            j.jdi = -1
            #this is a TERRIBLE hack. FIXME
            ptri = pointer_from_objref(j)
            j.jd_ptr = convert(Ptr{Ptr{Void}},ptri) 
            j.jdi_ptr =convert(Ptr{Int},ptri+8)    
            
            finalizer(j, ju_free)
            return j
        end
    end


    #makes all the necessary free() calls, faster than removing elements one by one.
    function ju_free(j::JudyDict)
        ccall((:JudyLFreeArray, _judylib), Int, (Ptr{Ptr{Void}}, Ptr{Void}), j.jd_ptr, C_NULL)
    end

    #returns the amount of memory used, as reported by judylib
    function ju_mem_used(j::JudyDict)
        ccall((:JudyLMemUsed, _judylib), Int, (Ptr{Void},), j.jd)
    end

    #returns pointer to value. If the key was present before, we point to the old value. 
    #Else, the value is initialized to zero.
    function ju_insert(j::JudyDict, idx::Int)    
         ccall((:JudyLIns, _judylib), Ptr{Int}, 
         (Ptr{Ptr{Void}}, Int, Ptr{Void}), 
         j.jd_ptr, idx, C_NULL)
    end
     

    #deletes entry, returns true if the key was present before.
    function ju_del(j::JudyDict, idx::Int)
        ccall((:JudyLDel, _judylib), Int,
         (Ptr{Ptr{Void}}, Int, Ptr{Void}), 
        j.jd_ptr, idx, C_NULL) == 1?true:false
    end

    #returns pointer to value, or C_NULL for missing keys.
    function ju_get(j::JudyDict, idx::Int)
        val_ptr = ccall((:JudyLGet, _judylib), Ptr{Int}, 
         (Ptr{Void}, Int, Ptr{Void}), 
         j.jd, idx, C_NULL)
         return val_ptr
    end

    #counts items stored between indices, inclusive on both sides
    function ju_count(j::JudyDict, idx_from::Int, idx_to::Int)
        ccall((:JudyLCount, _judylib), UInt, 
         (Ptr{Void}, Int, Int, Ptr{Void}), 
         j.jd, idx_from, idx_to, C_NULL)
    end

    #returns the nth key in sort-order, and a pointer to the corresponding value
    function ju_bycount(j::JudyDict, n::Int)
       # idx_ptr = Vector{Int}(1)
        valptr::Ptr{Int} = ccall((:JudyLByCount, _judylib), Int, 
         (Ptr{Void}, Int, Ptr{Int}, Ptr{Void}), 
         j.jd, n,  j.jdi_ptr, C_NULL)
         #idx::Int = idx_ptr[1]
         return( j.jdi, valptr)
    end

    #returns then ext key after idx (or possibly idx), and a pointer to its value (or C_NULL)
    function ju_next_inclusive(j::JudyDict, idx::Int)
        #idx_ptr = Vector{Int}(1)
         j.jdi = idx    
         valptr::Ptr{Int} = ccall((:JudyLFirst, _judylib), Int, 
         (Ptr{Void}, Ptr{Int}, Ptr{Void}), 
         j.jd, j.jdi_ptr, C_NULL)
         #idx_found::Int = idx_ptr[1]
         return( j.jdi, valptr)
    end

    #returns the next key strictly after idx, and a pointer to its value (or C_NULL).
    function ju_next(j::JudyDict, idx::Int)
       # idx_ptr = Vector{Int}(1)
         j.jdi = idx
         valptr::Ptr{Int} = ccall((:JudyLNext, "libJudy"), Int, 
         (Ptr{Void}, Ptr{Int}, Ptr{Void}), 
         j.jd, j.jdi_ptr, C_NULL)
         #idx_found::Int = idx_ptr[1]
         return( j.jdi, valptr)
    end

    #returns then ext key before idx (or possibly idx), and a pointer to its value (or C_NULL)
    function ju_prev_inclusive(j::JudyDict, idx::Int)
         j.jdi = idx
        valptr::Ptr{Int} = ccall((:JudyLLast, _judylib), Int, 
         (Ptr{Void}, Ptr{Int}, Ptr{Void}), 
         j.jd, j.jdi_ptr, C_NULL)
         #idx_found::Int = idx_ptr[1]
         return( j.jdi, valptr)
    end

    #returns the next key strictly before idx, and a pointer to its value (or C_NULL).
    function ju_prev(j::JudyDict, idx::Int)
         j.jdi = idx
        valptr::Ptr{Int} = ccall((:JudyLPrev, _judylib), Int, 
         (Ptr{Void}, Ptr{Int}, Ptr{Void}), 
         j.jd, j.jdi_ptr, C_NULL)
         return( j.jdi, valptr)
    end


    #convenience functions for making pointers convenient.
    getindex(ptr:: Ptr{T}, idx::Int64) where {T} = unsafe_load(ptr, idx)
    setindex!(ptr:: Ptr{T}, val::T ,idx::Int64) where {T} = unsafe_store!(ptr, val, idx)  
    
    
    #terrible API. 
    function getindex(jd::JudyDict, idx::Int64)
        valptr = ju_get(jd, idx)
        if valptr != C_NULL
            return valptr[1]
        else
            return Int(-1) #just for testing, want to skip proper handling of missing keys until a reasonable API is decided.
        end
    end

    function setindex!(jd::JudyDict,  val::Int64, idx::Int64)
        valptr = ju_insert(jd, idx)
        valptr[1]=val
        return nothing
    end
    
    function delete!(jd::JudyDict, idx::Int64)
        ju_del(jd, idx)
        return nothing
    end    
    
end #module
