BEGIN { behavioral_added = 0 }
/^# \{title\}$/ {
    print $0
    print ""
    print "## Behavioral Specification"
    print ""
    print "### User Experience"
    print "- **Input**: [What users provide]"
    print "- **Process**: [What users experience during interaction]"
    print "- **Output**: [What users receive]"
    print ""
    print "### Expected Behavior"
    print "[Describe WHAT the system should do, not HOW]"
    print ""
    print "### Interface Contract"
    print "```bash"
    print "# CLI Interface (if applicable)"
    print "command-name [options] <arguments>"
    print ""
    print "# API Interface (if applicable)"
    print "GET/POST/PUT/DELETE /endpoint"
    print "```"
    print ""
    print "### Success Criteria"
    print ""
    print "- [ ] [Measurable outcome 1]"
    print "- [ ] [Measurable outcome 2]"
    print ""
    print "### Validation Questions"
    print ""
    print "- [ ] Question about unclear requirements?"
    print "- [ ] Question about edge cases?"
    print "- [ ] Question about user expectations?"
    print ""
    behavioral_added = 1
    next
}
{ print }
EOF < /dev/null