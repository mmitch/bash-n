# Makefile - bash-n Makefile
#
# Copyright (C) 2019  Christian Garbs <mitch@cgarbs.de>
# Licensed under GNU GPL v3 or later.
#
# This file is part of bash-n.
#
# bash-n is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# bash-n is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with bash-n.  If not, see <http://www.gnu.org/licenses/>.

SHELL     := bash
TESTS     := $(wildcard *.test)
TEST_RUNS := $(patsubst %.test,%.test.run,$(TESTS))

all:	test

clean:
	rm -f *~

test:	$(TEST_RUNS)

autotest:
	-$(MAKE) test
	inotifywait -m -e modify -e create -e delete -e close_write -e move -r . | \
	while read -r EVENT; do \
		while read -r -t 0.1 EVENT; do :; done; \
		$(MAKE) test; \
	done

%.test.run: %.test
	$(SHELL) $<
