all: cleanup test

test: 
	@./code_coverage.sh

cleanup:
	@find ../../ -name "*.gcov" -exec rm {} \;
	@find . -name "*.log" -exec rm {} \;

clean:
	@find ../../ -name "*.gcno" -exec rm {} \;

coverage: 
