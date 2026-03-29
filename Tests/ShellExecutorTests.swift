import Testing
@testable import PPIOClaudeInstaller

@Suite("ShellExecutor Tests")
struct ShellExecutorTests {

    @Test func simpleCommand() async {
        let result = await ShellExecutor.run("echo hello")
        #expect(result.exitCode == 0)
        #expect(result.output == "hello")
    }

    @Test func failingCommand() async {
        let result = await ShellExecutor.run("false")
        #expect(result.exitCode != 0)
    }

    @Test func commandWithStderr() async {
        let result = await ShellExecutor.run("echo error >&2")
        #expect(result.error == "error")
    }

    @Test func commandWithEnvironment() async {
        let result = await ShellExecutor.run("echo $TEST_VAR", environment: ["TEST_VAR": "test_value"])
        #expect(result.output == "test_value")
    }

    @Test func invalidCommand() async {
        let result = await ShellExecutor.run("nonexistent_command_xyz_12345")
        #expect(result.exitCode != 0)
    }
}
