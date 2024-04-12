function [concat_matrix] = generate_lut_matrix(row_data, col_data, result_matrix)
%GENERATE_LUT_MATRIX concatenate 2 vectors which were multiplied and their
%result matrix
%   row_data - first multiplicand
%   col_data - second multiplicand
%   result_matrix -  result of multiplication col_data times row_data
%                    it looks like: 
%
%              0        col_data[1]           col_data[2]          col_data[3]
%           row_data[1] result_matrix[1,1]  result_matrix[1,2]  result_matrix[1,3]
%           row_data[2] result_matrix[2,1]  result_matrix[2,2]  result_matrix[2,3]
%           row_data[3] result_matrix[3,1]  result_matrix[3,2]  result_matrix[3,3]
%


concat_arr = zeros(size(result_matrix)+1);
concat_arr(1,2:end) = row_data; 
concat_arr(2:end,1) = col_data;
concat_arr(2:end,2:end) = result_matrix;

concat_matrix = concat_arr;
end