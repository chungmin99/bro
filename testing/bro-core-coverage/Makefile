all: cleanup test

test: 
	@./code_coverage.sh

cleanup:
	@find ../../ -name "*.gcov" -exec rm {} \;
	@rm coverage.log

clean:
	@find ../../ -name "*.gcno" -exec rm {} \;

coverage: 
