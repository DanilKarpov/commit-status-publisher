<%@ page import="jetbrains.buildServer.vcs.impl.VcsLabeler" %>
<%@ include file="/include-internal.jsp"%>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props" %>
<%@ taglib prefix="intprop" uri="/WEB-INF/functions/intprop" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>
<jsp:useBean id="buildForm" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm" scope="request"/>

<c:set var="customMessageToggle" value="<%=VcsLabeler.FEATURE_TOGGLE_CUSTOM_LABEL_MESSAGE%>"/>
<c:set var="customMessageEnabled" value="${intprop:getBooleanOrTrue(customMessageToggle)}"/>

<style type="text/css">
  dl.messagePatternNote {
    margin-block-start: 0;
    margin-block-end: 0;
  }

  dl.messagePatternNote dt, dl.messagePatternNote dd {
    display: inline;
  }

  dl.messagePatternNote dt {
    font-weight: bold;
  }

  dl.messagePatternNote dt:after {
    content: ":";
  }

  dl.messagePatternNote dd {
    margin-inline-start: 0;
  }

  div.longNote {
    width: 40em;
  }

  div.longNote.warningNote {
    color: var(--ring-warning-color);
  }
</style>

<tr>
  <td colspan="2"><em>This build feature sets a label on a chosen VCS root upon build completion.</em></td>
</tr>
<tr class="noBorder">
  <th><label for="vcsRootId">VCS root to label:</label><bs:help file="VCS+Labeling"/></th>
  <td>
    <props:selectProperty name="vcsRootId" style="width: 99%;" enableFilter="true">
      <props:option value="">-- Choose VCS root to label --</props:option>
      <props:option value="__ALL__">&lt;All attached VCS roots&gt;</props:option>
      <c:forEach items="${buildForm.vcsRootsBean.vcsRootsWithLabelingSupport}" var="vcsRoot">
        <props:option value="${vcsRoot.externalId}"><c:out value="${vcsRoot.name}"/></props:option>
      </c:forEach>
    </props:selectProperty>
    <span class="error" id="error_vcsRootId"></span>
  </td>
</tr>
<tr class="noBorder">
  <th><label for="labelingPattern">Labeling pattern:</label></th>
  <td><props:textProperty name="labelingPattern" className="longField textProperty_max-width js_max-width"/></td>
</tr>
<c:if test="${buildForm.template or buildForm.branchesConfigured}">
  <tr class="noBorder">
    <th>Label builds in branches:</th>
    <td>
      <c:set var="note">Newline-delimited set of rules in the form of +|-:logical branch name (with an optional * placeholder)<bs:help file="Branch+Filter"/></c:set>
      <props:multilineProperty name="branchFilter" linkTitle="Branch filter" cols="35" rows="3" className="buildTypeParams" note="${note}"/>
      <span class="error" id="error_branchFilter"></span>

      <script type="text/javascript">
      BS.BranchesPopup.attachHandler('${buildForm.settingsId}', 'branchFilter');
      <c:if test="${buildForm.vcsRootsBean.defaultExcluded}">
        if ($('vcsRootId').value == '' && $('branchFilter').value == '+:<default>') {
          <%--
          when new feature is added (vcsRootId is empty) and default branch is excluded,
          configure a branch filter to include builds in all branches, because there will
          be no builds in the default branch
           --%>
          $('branchFilter').value = '+:*';
        }
      </c:if>
      </script>
    </td>
  </tr>
</c:if>

<c:if test="${customMessageEnabled}">
  <tr class="advancedSetting">
    <th><label for="messagePattern">Message format:</label></th>
    <td>
      <c:set var="messageNote">
        <div class="longNote warningNote">Do not reference parameters with sensitive data to avoid leaks.</div>
        <div class="longNote">Different VCS types use the resulting message strings differently.</div>
        <dl class="messagePatternNote">
          <div class="longNote">
            <dt>Perforce</dt>
            <dd>uses the message as part of the label's "Description" field</dd>
          </div>
          <div class="longNote">
            <dt>Git</dt>
            <dd>passes the resulting string to the tag message argument</dd>
          </div>
          <div class="longNote">
            <dt>Other types</dt>
            <dd>ignore this custom string</dd>
          </div>
        </dl>
      </c:set>
      <props:multilineProperty name="messageFormat"
                               linkTitle="Custom label message format"
                               expanded="true"
                               cols="35"
                               rows="3"
                               className="buildTypeParams"
                               note="${messageNote}"/>
    </td>
  </tr>
</c:if>

<tr class="noBorder">
  <th></th>
  <td><props:checkboxProperty name="successfulOnly" value="true"/> <label for="successfulOnly">Label successful builds only</label></td>
</tr>