<%@ include file="/include-internal.jsp"%>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props" %>
<%@ taglib prefix="l" tagdir="/WEB-INF/tags/layout" %>

<jsp:useBean id="approvalConstants" class="jetbrains.buildServer.buildFeatures.approvals.ApprovalConstants"/>

<style type="text/css">
    #approvalRulesField .smallNote {
        width: unset;
    }
</style>

<tr>
    <td colspan="2">
        <em>
            Allows requesting an approval before a build will be assigned to an agent.<bs:help file="Build+Approval"/><br/>        </em>
    </td>
</tr>

<tr id="approvals_count">
    <th><label for="rules">Approval rules:<l:star/></label></th>
    <td id="approvalRulesField">
        <props:multilineProperty name="rules" linkTitle="Specify approval rules" className="longField" cols="20" rows="5" expanded="true"
                                 note="Use <code>user:&lt;username&gt;</code> for individuals and <code>group:&lt;group key&gt;:&lt;required count&gt;</code> for groups (group keys are case-sensitive).
                                       Each new line adds to a previous ruleset using the logical \"AND\" operator. To combine users and groups with a shared vote count, use brackets: <code>(users:johndoe,janedoe,groups:ADMINS,DEVS):2</code>" />
        <span class="error" id="error_rules"></span>
    </td>
</tr>

<tr class="advancedSetting" id="timeout">
    <th><label for="timeout">Timeout in:</label></th>
    <td>
        <props:textProperty name="timeout" className="mediumField"/>
        <span class="smallNote">Time (in minutes) before the build is cancelled, defaults to 360 minutes</span>
        <span class="error" id="error_timeout"></span>
    </td>
</tr>

<tr class="advancedSetting" id="manual_start_is_approval">
    <th><label for="manualStartIsApproval">Auto-approval:</label></th>
    <td>
        <props:checkboxProperty name="manualStartIsApproval"/>
        <span class="smallNote">If started by user with sufficient permissions, mark build as approved by user</span>
    </td>
</tr>