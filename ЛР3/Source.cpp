#include <iostream>
#include <string>
#include <Windows.h>

extern "C" void __fastcall change_str(char* str, int size);



std::string buf;

int main()
{
	setlocale(LC_ALL, "Russian");
	std::cout << "¬ведите строку: ";
	std::cin >> buf;
	
	change_str(const_cast<char*>(buf.c_str()), buf.size());
	std::cout << buf << "\n";
	
	return 0;
}