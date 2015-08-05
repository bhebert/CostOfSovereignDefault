capture program drop GDP_BS_helper
program GDP_BS_helper , eclass sortpreserve

	syntax anything, model_name(namelist) coef_name(namelist) stderrs(string) [randomize]
		
	disp "anything: `anything'"
	disp "model_name: `model_name'"
	disp "stderrs: `stderrs'"
	disp "randomize: `randomize'"
	
	local err 0
	capture confirm matrix `model_name'_b
	if _rc local err 1
	capture confirm matrix `model_name'_V
	if _rc local err 1
	
	if `err' == 1 {
		disp "Warning: `model_name'_b or `model_name'_V matrix not found."
		disp "Setting `model_name' = ValueIndex"
		matrix `model_name'_b = J(1,1,1)
		matrix `model_name'_V = J(1,1,0)
		matrix rownames `model_name'_V = ValueIndex_US
		matrix colnames `model_name'_V = ValueIndex_US
		matrix rownames `model_name'_b = ValueIndex_US
	}
	
	local has_coef 1
	capture confirm matrix `coef_name'
	if _rc {
		disp "Warning: vector of coeffs for std err calculation does not exist"
		disp "Ignoring estimation error"
		local has_coef 0
	}
	
	matrix list `model_name'_b
	matrix list `model_name'_V
	matrix list `coef_name'
	
	local indnames : rownames `model_name'_b
	
	disp "indnames: `indnames'"
	
	tempname coef2 model_var chol shifts unifs b2 vtemp
	matrix `coef2' = `model_name'_b
	
	matrix list `coef2'
	
	local i = 0
	foreach ind_name in `indnames' {
		local i = `i' + 1
		if `has_coef' == 1 {
			matrix temp = `coef_name'["`ind_name'",1]
			matrix `coef2'[`i',1] = temp
		}
		else{
			matrix `coef2'[`i',1] = 0
		}
	}
	
	matrix list `coef2'
	
	matrix `model_var' = `coef2'' * `model_name'_V * `coef2'
	
	matrix list `model_var'
	
	if "`randomize'" == "randomize" {
		matrix `unifs' = matuniform(`i',1)

		
		forvalues j = 1/`i' {
			local val = `unifs'[`j',1]
			local val = invnorm(`val')
			matrix `unifs'[`j',1] = `val'
		}
		
		matrix `chol' = cholesky(`model_name'_V)
		matrix `shifts' = `chol' * `unifs'
		
		matrix rownames `shifts' = `indnames'
		matrix list `shifts'
		matrix `b2' = `model_name'_b + `shifts'
	}
	else {
		matrix `b2' = `model_name'_b
	}
	
	
	preserve
	drop if ~regexm("`indnames'",firmname)
	

	
	
	gen weight = 0
	local nw = 0
	local lastname
	foreach ind_name in `indnames' {
		local nw = `nw' + 1
		matrix temp = `b2'["`ind_name'",1]
		local iweight = temp[1,1]
		replace weight = `iweight' if regexm("`ind_name'",firmname)
		local lastname `ind_name'
	}
	
	ta firmname weight
	
	sort date firmname
	
	by date: egen wret = total(return_ * weight)
	by date: egen wsum = count(return_)
	
	disp "lastname: `lastname'"
	ta firmname
	drop if ~regexm("`lastname'",firmname)
	replace return_ = wret
	replace return_ = . if wsum < `nw'
	
	drop if return_ == .
	
	drop enum nnum ins_cds ins_ret
	
	sort firmname date

	by firmname: egen enum = sum(eventvar)
	by firmname: egen nnum = sum(nonevent)
	
	gen ins_cds = eventvar * cds_ * (enum+nnum)/(enum) - (1-eventvar)*cds_*(enum+nnum)/(nnum)
	gen ins_ret = eventvar * return_ * (enum+nnum)/(enum) - (1-eventvar)*return_*(enum+nnum)/(nnum)
	
	su enum 
	local num_e = `r(mean)'
	
	ta date if eventvar == 1
	
	`anything', `stderrs'
	
	local coef1 = _b[cds_]
	local se3 = _se[cds_]
	
	local var2 = `model_var'[1,1]
	
	local se1 = sqrt(`se3'*`se3' + `var2')
	
	disp "se3: `se3'"
	disp "se1: `se1'"
	
	ereturn scalar se1 = `se1'
	ereturn scalar num_e = `num_e'
	
end
