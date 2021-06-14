
#### **Program Description**
##### **Overview**

IA-32 MASM Assembly implementation of converting strings to integers (SDWORD) and back again.  Receives and validates 10 user entered strings then calculates the average and sum displaying the results as a string.

##### **Implementation Details** 
-   Implements two macros `mGetString` and `mDisplayString` for string processing. These macros use Irvine’s  `ReadString`  to get input from the user, and  `WriteString`  procedures to display output.
    -   `mGetString`: Displays a prompt  _(input parameter, by reference_), then get the user’s keyboard input into a memory location  _(output parameter, by reference_). Provides a count  _(input parameter, by value)_  for the length of input string to be accommodated and a provides a number of bytes read (_output parameter, by reference)_  by the macro.
    -   `mDisplayString`: Prints the string which is stored in a specified memory location  _(input parameter, by reference_).
-   Implements procedures for signed integers which use string primitive instructions `LODSB` and `STOSB`
    -   `ReadVal`:
        1.  Invokes the  `mGetString`  macro (see parameter requirements above) to get user input in the form of a string of digits.
        2.  Converts (using string primitives) the string of ascii digits to its numeric value representation (SDWORD), validating the user’s input is a valid number (no letters, symbols, etc).
        3.  Stores this one value in a memory variable  _(output parameter, by reference)._
    -   `WriteVal`:
        1.  Converts a numeric SDWORD value  _(input parameter, by value_)  to a string of ascii digits
        2.  Invokes the  `mDisplayString`  macro to print the ascii representation of the SDWORD value to the output.
-   Test program (in  `main`) uses the  `ReadVal`  and  `WriteVal`  procedures above to:
    1.  Get 10 valid integers from the user. `ReadVal`  is called within the loop in  `main`. 
    2.  Store these numeric values in an array.
    3.  Display the integers, their sum, and their average by using  `WriteVal`  procedure.


#### **Program Features**

1.  User’s numeric input validated by:
    1.  Reading the user's input as a string and converting the string to numeric form.
    2.  If the user enters non-digits other than something which will indicate sign (e.g. ‘+’ or ‘-‘), or the number is too large for 32-bit registers, an error message should be displayed and the number should be discarded.
    3.  If the user enters nothing (empty input), displays an error and re-prompts for input.
2.  Conversion routines  use the  `LODSB`  and  `STOSB`  operators for dealing with strings.
3.  All procedure parameters  passed on the runtime stack. Strings passed by reference
4.  Prompts, identifying strings, and other memory locations passed by address to the macros.
5.  Used registers  saved and restored by the called procedures and macros.
6.  The stack frame  cleaned up by the called procedure. (STDcall calling convention)
7.  Procedures (except  `main`)  do not reference data segment variables by name.
8.  The program  uses  _Register Indirect_  addressing for integer (SDWORD) array elements, and  _Base+Offset_  addressing for accessing parameters on the runtime stack.
9.  Procedures use local variables when appropriate. 

#### **Sample Output**
![sampleOutput](https://user-images.githubusercontent.com/66268023/121953163-d6b99200-cd22-11eb-8261-1a73b1be53f2.JPG)

#### **Usage**
1. Clone the repository onto your local machine
2. Download the Irvine library from http://asmirvine.com/gettingStartedVS2019/Irvine.zip 
3. Extract the contents of this ZIP file into the C:\ directory. If the files were extracted properly, the library file should exist in C:\Irvine\Irvine32.lib
4. Open the Project.sln file from the cloned repository using Visual Studio
5. Run the .asm file from within Visual Studio

#### **Notes**

1.  The total sum of the valid numbers is assumed to fit inside a 32 bit register. [-2147483648....2147483647]
2. The maximum length of user input is 15 characters.
3.  When displaying the average, the result is rounded down (floor) to the nearest integer.
4.  This program was created as the Sprint 2021 final project of CS 271 Computer Architecture and Assembly Language at Oregon State University.
