-- .parameter init
-- .parameter set @first_name 'Ilya'
-- .parameter set @last_name 'Lenin'

SELECT * FROM members WHERE first_name = :fn AND last_name = :ln;
