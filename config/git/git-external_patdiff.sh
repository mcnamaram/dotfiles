#!/usr/bin/env bash

patdiff $2 $5 -alt-old a/$5 -alt-new b/$5 | cat
