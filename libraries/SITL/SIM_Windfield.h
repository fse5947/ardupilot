#pragma once

#include <Python.h>
#define NPY_NO_DEPRECATED_API NPY_1_7_API_VERSION
#include <vector>
#include <iostream>


class Windfield {
public:
    // Windfield(const char* thermal_env_file);
    Windfield();

    ~Windfield() {Py_Finalize();}

    void update_time(float time_now_s);

    std::vector<float> get_updraft(const std::vector<float> &current_position);

private:
    std::vector<float> listTupleToVector_Float(PyObject* incoming);
    PyObject* vectorToList_Float(const std::vector<float> &data);

    PyObject* wind_field;

    // const char* thermal_file;

};
