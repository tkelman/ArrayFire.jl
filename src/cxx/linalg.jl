
# BLAS operations
import Base: dot, A_mul_Bt, At_mul_B, At_mul_Bt, A_mul_Bc,
    Ac_mul_B, Ac_mul_Bc, transpose, ctranspose, transpose!, ctranspose!

dot{T,S}(lhs::AFAbstractArray{T}, rhs::AFAbstractArray{S}) = 
        AFArray{af_promote(T,S)}(af_dot(lhs, rhs))

# Matmul
*{T,S}(a::AFAbstractArray{T}, b::AFAbstractArray{S}) =
    AFArray{af_promote(T,S)}(af_matmul(a,b))
*{T,S,V}(a::AFAbstractArray{T}, b::AFAbstractArray{S}, c::AFAbstractArray{V}) =
    AFArray{af_promote(af_promote(T,S), V)}(af_matmul3(a,b,c))
*{T,S,V,W}(a::AFAbstractArray{T}, b::AFAbstractArray{S}, c::AFAbstractArray{V}, d::AFAbstractArray{W}) =
    AFArray{af_promte(af_promote(af_promote(T,S), V), W)}(af_matmul4(a,b,c,d))

function _matmul(a::AFAbstractArray, b::AFAbstractArray;
    lhsProp = AF_MAT_NONE, rhsProp = AF_MAT_NONE)
    out = af_matmul_flags(a, b, lhsProp, rhsProp)
    AFArray{backend_eltype(out)}(out)
end

# with transpose
function A_mul_Bt(a::AFAbstractArray, b::AFAbstractArray)
    out = af_matmulNT(a,b)
    AFArray{backend_eltype(out)}(out)
end

function At_mul_B(a::AFAbstractArray, b::AFAbstractArray)
    out = af_matmulTN(a,b)
    AFArray{backend_eltype(out)}(out)
end

function At_mul_Bt(a::AFAbstractArray, b::AFAbstractArray)
    out = af_matmulTT(a,b)
    AFArray{backend_eltype(out)}(out)
end

# with complex conjugate
A_mul_Bc(a::AFAbstractArray, b::AFAbstractArray) =
    _matmul(a,b,rhsProp=AF_MAT_CTRANS)
Ac_mul_B(a::AFAbstractArray, b::AFAbstractArray) =
    _matmul(a,b,lhsProp=AF_MAT_CTRANS)
Ac_mul_Bc(a::AFAbstractArray, b::AFAbstractArray) =
    _matmul(a,b,lhsProp=AF_MAT_CTRANS,rhsProp=AF_MAT_CTRANS)

# transpose
transpose{T}(x::AFAbstractArray{T}) = AFArray{T}(af_transpose(x))
ctranspose{T}(x::AFAbstractArray{T}) = AFArray{T}(af_ctranspose(x))

transpose!{T}(x::AFAbstractArray{T}) = af_transposeInPlace(x)
ctranspose!{T}(x::AFAbstractArray{T}) = af_ctransposeInPlace(x)

# solve

# TODO : The documentation says only AF_MAT_LOWER/AF_MAT_UPPER are supported
# once AF_MAT_(C)TRANS is supported this could be useful for A_rdiv, etc
# TODO : Think about integrating solveLU in `\` so it becomes a poly algorithm like base. 

import Base: \

\{S,T}(a::AFAbstractArray{S}, b::AFAbstractArray{T}) = AFArray{af_promote(T,S)}(af_solve(a, b);)

# Factorizations

import Base.LinAlg: chol, chol!, PosDefException

#Cholesky
function _chol{T}(a::AFMatrix{T}, is_upper::Bool)
    out = AFArray()
    info = af_cholesky(out, a, is_upper)
    info > 0 && throw(PosDefException(info))
    out = is_upper ? (AFArray{T}(af_upper(out))) : (AFArray{T}(af_lower(out)))
end

function _chol!{T}(a::Matrix{T}, is_upper::Bool)
    info = af_choleskyInPlace(a, is_upper)
    info > 0 && throw(PosDefException(info))
    b = is_upper ? (AFArray{T}(af_upper(a))) : (AFArray{T}(af_lower(a)))
    return b 
end

chol(a::AFMatrix, ::Type{Val{:U}}) = _chol(a, true)
chol(a::AFMatrix, ::Type{Val{:L}}) = _chol(a, false)
chol(a::AFMatrix) = chol(a,Val{:U})

chol!(a::AFMatrix, ::Type{Val{:U}}) = _chol!(a, true)
chol!(a::AFMatrix, ::Type{Val{:L}}) = _chol!(a, false)
chol!(a::AFMatrix) = chol!(a,Val{:U})

#LU 
function lu(a::AFMatrix)
    l = AFArray() 
    u = AFArray()
    p = AFArray()
    af_lu(l, u, p, a)
    AFArray{backend_eltype(l)}(l), AFArray{backend_eltype(u)}(u), (AFArray{backend_eltype(p)}(p) + 1)
end

#QR
function qr(a::AFMatrix)
    q = AFArray()
    r = AFArray()
    tau = AFArray()
    af_qr(q, r, tau, a)
    AFArray{backend_eltype(q)}(q), AFArray{backend_eltype(r)}(r), AFArray{backend_eltype(tau)}(tau)
end

#SVD
function svd(a::AFMatrix)
    u = AFArray()
    s = AFArray()
    vt = AFArray()
    af_svd(u, s, vt, a)
    AFArray{backend_eltype(u)}(u), AFArray{backend_eltype(s)}(s), AFArray{backend_eltype(vt)}(vt)
end

#Mat ops

import Base: det, inv, norm

function det{T}(a::AFMatrix{T}) 
    if ndims(a) != 2
        throw(DimensionMismatch("Input isn't a matrix"))
    else
        return af_det(a)
    end
end

function inv(a::AFMatrix)
    if ndims(a) != 2
        throw(DimensionMismatch("Input isn't a matrix"))
    else
        return AFArray{Float32}(af_inverse(a))
    end
end

norm(a::AFAbstractArray) = af_norm(a)
rank(a::AFMatrix) = af_rank(a)
