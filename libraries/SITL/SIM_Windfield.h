#pragma once

#include <Python.h>
#define NPY_NO_DEPRECATED_API NPY_1_7_API_VERSION
#include <vector>
#include <iostream>


class Windfield {
public:
    Windfield();

    ~Windfield() {Py_Finalize();}

private:
    std::vector<float> listTupleToVector_Float(PyObject* incoming);
    PyObject* vectorToList_Float(const std::vector<float> &data);

};
