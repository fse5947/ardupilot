#include "SIM_Windfield.h"


Windfield::Windfield() { //const char* thermal_env_file

    // thermal_file = new char[strlen(thermal_env_file) + 1]; // +1 for null terminator
    // strcpy(thermal_file, thermal_env_file);

    Py_Initialize();

    PyObject *sys_path = PySys_GetObject("path");
    PyList_Append(sys_path, PyUnicode_FromString("/windfield/utils"));
    
    PyObject* wind_field_file = PyImport_ImportModule((char*)"wind_field");

    if (wind_field_file == NULL) {
        PyErr_Print();
        std::exit(1);
    }

    PyObject* determ_wind_class = PyObject_GetAttrString(wind_field_file,(char*)"DeterministicWindField");

    if (determ_wind_class == NULL) {
        PyErr_Print();
        std::exit(1);
    }

    PyObject *args = PyTuple_New(0);
    PyObject *kwargs = Py_BuildValue("{s:s}", "thermal_env_file", "/wind_fields/12.00h_AE_H_instance0_v1.0.json");
    wind_field = PyObject_Call(determ_wind_class, args, kwargs);

    if (wind_field == NULL) {
        PyErr_Print();
        std::exit(1);
    }

    PyObject* wind_field_area = PyObject_CallMethod(wind_field, "get_area", NULL);

    if (wind_field_area == NULL) {
        PyErr_Print();
        std::exit(1);
    }

    std::cout << "Wind field area: " << PyFloat_AsDouble(wind_field_area) << std::endl;

}

std::vector<float> Windfield::listTupleToVector_Float(PyObject* incoming) {
	std::vector<float> data;
	if (PyTuple_Check(incoming)) {
		for(Py_ssize_t i = 0; i < PyTuple_Size(incoming); i++) {
			PyObject *value = PyTuple_GetItem(incoming, i);
			data.push_back( PyFloat_AsDouble(value) );
		}
	} else {
		if (PyList_Check(incoming)) {
			for(Py_ssize_t i = 0; i < PyList_Size(incoming); i++) {
				PyObject *value = PyList_GetItem(incoming, i);
				data.push_back( PyFloat_AsDouble(value) );
			}
		} else {
            std::cout << "Passed PyObject pointer was not a list or tuple!" << std::endl;
            std::exit(1);
		}
	}
	return data;
}

PyObject* Windfield::vectorToList_Float(const std::vector<float> &data) {
    PyObject* listObj = PyList_New( data.size() );
	if (!listObj) {
        std::cout << "Unable to allocate memory for Python list" << std::endl;
        std::exit(1);
    }
	for (unsigned int i = 0; i < data.size(); i++) {
		PyObject *num = PyFloat_FromDouble( (double) data[i]);
		if (!num) {
			Py_DECREF(listObj);
			std::cout << "Passed PyObject pointer was not a list or tuple!" << std::endl;
            std::exit(1);
        }
		PyList_SET_ITEM(listObj, i, num);
	}
	return listObj;
}

void Windfield::update_time(float time_now_s){
    
    PyObject* wind_update_time = PyObject_CallMethod(wind_field, "update_time", "f", time_now_s);

    if (wind_update_time == NULL) {
        PyErr_Print();
        std::exit(1);
    }
}

std::vector<float> Windfield::get_updraft(const std::vector<float> &current_position) {

    PyObject* wind = PyObject_CallMethod(wind_field, "get_wind_as_list", "[f,f,f]", current_position[0], current_position[1], current_position[2]);

        if (wind == NULL) {
            PyErr_Print();
            std::exit(1);
        }

    std::vector<float> wind_out = listTupleToVector_Float(wind);
    return wind_out;
}