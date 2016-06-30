# borrowed from algesten/fnuc
merge = (t, os...) -> t[k] = v for k,v of o for o in os; t

module.exports = merge