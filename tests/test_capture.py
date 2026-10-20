import importlib.util
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location("capture", Path(__file__).resolve().parents[1] / "capture.py")
capture = importlib.util.module_from_spec(spec)
spec.loader.exec_module(capture)


class Insert(unittest.TestCase):
    def test_below_frontmatter(self):
        self.assertEqual(capture.insert("---\ntags: [inbox]\n---\n- [ ] old\n", "- [ ] new"),
                         "---\ntags: [inbox]\n---\n- [ ] new\n- [ ] old\n")

    def test_top_without_frontmatter(self):
        self.assertEqual(capture.insert("\nold note\n", "new"), "new\n\nold note\n")

    def test_frontmatter_only_without_trailing_newline(self):
        self.assertEqual(capture.insert("---\na: 1\n---", "x"), "---\na: 1\n---\nx\n")

    def test_unclosed_frontmatter_is_just_text(self):
        self.assertEqual(capture.insert("---\nnot closed\n", "x"), "x\n---\nnot closed\n")


class Capture(unittest.TestCase):
    def test_task_written_atomically_and_whitespace_collapsed(self):
        path = Path(tempfile.mkdtemp()) / "inbox" / "todo.md"
        self.assertTrue(capture.capture(str(path), "task", "  call   mom \n"))
        self.assertTrue(capture.capture(str(path), "task", "buy milk"))
        self.assertEqual(path.read_text(), "- [ ] buy milk\n- [ ] call mom\n")
        self.assertEqual([p.name for p in path.parent.iterdir()], ["todo.md"])

    def test_empty_text_writes_nothing(self):
        path = Path(tempfile.mkdtemp()) / "notes.md"
        self.assertFalse(capture.capture(str(path), "line", "   "))
        self.assertFalse(path.exists())

    def test_keeps_permissions(self):
        path = Path(tempfile.mkdtemp()) / "notes.md"
        path.write_text("old\n")
        path.chmod(0o600)
        capture.capture(str(path), "line", "new")
        self.assertEqual(path.stat().st_mode & 0o777, 0o600)


if __name__ == "__main__":
    unittest.main()
