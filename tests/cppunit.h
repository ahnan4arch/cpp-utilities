#ifndef CPPUNIT_H
#define CPPUNIT_H

#include "./testutils.h"

#include <cppunit/extensions/TestFactoryRegistry.h>
#include <cppunit/ui/text/TestRunner.h>
#include <cppunit/TestPath.h>

#include <iostream>

using namespace std;
using namespace TestUtilities;
using namespace CPPUNIT_NS;

/*!
 * \brief Performs unit tests using cppunit.
 */
int main(int argc, char **argv)
{
    TestApplication testApp(argc, argv);
    if(testApp) {
        // run tests
        TextUi::TestRunner runner;
        TestFactoryRegistry &registry = TestFactoryRegistry::getRegistry();
        if(!testApp.unitsSpecified() || testApp.units().empty()) {
            // no units specified -> test all
            runner.addTest(registry.makeTest());
        } else {
            // pick specified units from overall test
            Test *overallTest = registry.makeTest();
            for(const char *unit : testApp.units()) {
                try {
                    runner.addTest(overallTest->findTest(unit));
                } catch(const invalid_argument &) {
                    cerr << "The specified test unit \"" << unit << "\" is not available and will be ignored." << endl;
                }
            }
        }
        return !runner.run(string(), false);
    } else {
        return -1;
    }
}

#endif // CPPUNIT_H
