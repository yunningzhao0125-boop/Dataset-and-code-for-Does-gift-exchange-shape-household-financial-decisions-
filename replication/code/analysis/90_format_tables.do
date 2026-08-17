* Word-visible three-line formatting for Tables 1-8.
version 18.0
set more off
quietly do "config/01_paths.do"

mata:
real rowvector irfa_cellx_values(string scalar s)
{
    real rowvector values
    real scalar p, first, last, code
    string scalar rest
    values = J(1, 0, .)
    rest = s
    while ((p = strpos(rest, "\cellx")) > 0) {
        first = p + 6
        last = first
        while (last <= strlen(rest)) {
            code = ascii(substr(rest, last, 1))
            if (code < 48 | code > 57) break
            last++
        }
        if (last > first) {
            values = (values, strtoreal(substr(rest, first, last - first)))
        }
        rest = substr(rest, last, .)
    }
    return(values)
}

string scalar irfa_normalize_cellx(
    string scalar s, real scalar target_first, real scalar target_last)
{
    real rowvector values
    real scalar n, j, p, first, last, code, new_value
    string scalar rest, output
    values = irfa_cellx_values(s)
    n = cols(values)
    if (n < 2) return(s)
    rest = s
    output = ""
    for (j = 1; j <= n; j++) {
        p = strpos(rest, "\cellx")
        first = p + 6
        last = first
        while (last <= strlen(rest)) {
            code = ascii(substr(rest, last, 1))
            if (code < 48 | code > 57) break
            last++
        }
        if (j == 1) new_value = target_first
        else if (j == n) new_value = target_last
        else new_value = round(target_first + ///
            (target_last - target_first) * (j - 1) / (n - 1))
        output = output + substr(rest, 1, first - 1) + ///
            strtrim(strofreal(new_value, "%20.0f"))
        rest = substr(rest, last, .)
    }
    return(output + rest)
}

void irfa_rtf_visible_rules(string scalar filename)
{
    string colvector lines
    string scalar line, top_rule, bottom_rule
    real rowvector values
    real scalar input, output, i, target_first, target_last
    real scalar has_top, has_bottom, top_count
    if (strpos(strlower(filename), "table_01_") | ///
            strpos(strlower(filename), "table_03_")) return
    lines = J(0, 1, "")
    input = fopen(filename, "r")
    while ((line = fget(input)) != J(0, 0, "")) lines = lines \ line
    fclose(input)
    target_first = 0
    target_last = 0
    for (i = 1; i <= rows(lines); i++) {
        values = irfa_cellx_values(lines[i])
        if (cols(values) >= 2) {
            if (values[1] > target_first) target_first = values[1]
            if (values[cols(values)] > target_last) ///
                target_last = values[cols(values)]
        }
    }
    top_rule = "\clbrdrt\brdrw10\brdrs"
    bottom_rule = "\clbrdrb\brdrw10\brdrs"
    top_count = 0
    for (i = 1; i <= rows(lines); i++) {
        line = lines[i]
        if (strpos(line, "{\pard \par}")) top_count = 0
        has_top = strpos(line, top_rule) > 0
        has_bottom = strpos(line, bottom_rule) > 0
        line = subinstr(line, top_rule, "", .)
        line = subinstr(line, bottom_rule, "", .)
        if (has_top) {
            top_count++
            if (top_count <= 3) ///
                line = subinstr(line, "\cellx", top_rule + "\cellx", .)
        }
        if (has_bottom & strpos(line, "{Observations}")) ///
            line = subinstr(line, "\cellx", bottom_rule + "\cellx", .)
        if (strpos(line, top_rule) | strpos(line, bottom_rule)) ///
            line = subinstr(line, "{}\cell", "{\~}\cell", .)
        lines[i] = irfa_normalize_cellx(line, target_first, target_last)
    }
    unlink(filename)
    output = fopen(filename, "w")
    for (i = 1; i <= rows(lines); i++) fput(output, lines[i])
    fclose(output)
}
end

local tables Table_02_Summary_Statistics.rtf Table_04_Baseline.rtf ///
    Table_05_Robustness.rtf Table_06_Instrumental_Variables.rtf ///
    Table_07_Mechanisms.rtf Table_08_Heterogeneity.rtf
foreach f of local tables {
    mata: irfa_rtf_visible_rules("$IRFA_REPRODUCED/`f'")
}

display "TABLE_FORMATTING=PASS"
