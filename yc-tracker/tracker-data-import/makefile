.SILENT: package

package:
	echo "=========================================="
	echo "= Bilding zip archive for cloud finction ="
	echo "==========================================\n"
	rm -f build/tracker-data-import.zip
	zip -r build/tracker-data-import.zip requirements.txt \
		tracker_import.py isoduration/* \
		-x *.pyc -x isoduration/__pycache__/\* \
		-x isoduration/formatter/__pycache__/\* \
		-x isoduration/operations/__pycache__/\* \
		-x isoduration/parser/__pycache__/\*
