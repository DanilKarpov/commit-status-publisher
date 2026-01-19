<%@ page import="jetbrains.buildServer.serverSide.vcs.spec.AttributesBranchFiltersProperties" %>
<%@ include file="/include.jsp" %>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props" %>
<jsp:useBean id="propertiesBean" type="jetbrains.buildServer.controllers.BasePropertiesBean" scope="request"/>
<jsp:useBean id="buildForm" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm" scope="request"/>
<c:set var="isAttributesEnabled" value="<%= AttributesBranchFiltersProperties.isEnabledTriggers() %>"/>
<l:settingsGroup title="Branch Filter"/>

<bs:linkCSS>
  /css/pager.css
  /css/filePopup.css
</bs:linkCSS>

<style type="text/css">
  .clickable-text {
    color:  var(--ring-link-color);
    cursor: pointer;
  }
</style>

<tr>
  <td style="vertical-align: top;">
    <label for="branchFilter" class="rightLabel">Branch filter:</label><bs:help file="Branch+Filter"/>
  </td>
  <td style="vertical-align: top;">

    <c:set var="note">
      <c:choose>
        <c:when test="${isAttributesEnabled}">
          New-line delimited list of logical branch names with an optional "*" placeholder (+|-: &lt;name&gt;) or pull request conditions (+|-pr: &lt;properties&gt;).<bs:help file="Branch Filter"/>
        </c:when>
        <c:otherwise>
          Newline-delimited set of rules in the form of +|-:logical branch name (with an optional * placeholder).<bs:help file="Branch+Filter"/>
        </c:otherwise>
      </c:choose>
      <br>
      Click the <span class="clickable-text" onclick="document.getElementById('handle_helper_branchFilter').click()">Magic wand button</span> to invoke the filter expression editor
    </c:set>
    <props:multilineProperty name="branchFilter" linkTitle="Edit Branch Filter" cols="35" rows="3" note="${note}"/>
    <script type="text/javascript">
      <%--@elvariable id="buildTypeIdsFunc" type="java.lang.String"--%>
      <c:if test="${not empty buildTypeIdsFunc}">
        BS.BranchFilterHelperPopup.attachHandler('branchFilter', ["branchPattern", "pullRequest"], [function() {return BS.BranchesPopup.createBuildTypesParams(${buildTypeIdsFunc})}, "originalSettingsId=${buildForm.settingsId}"]);
      </c:if>
      <c:if test="${empty buildTypeIdsFunc}">
        BS.BranchFilterHelperPopup.attachHandler('branchFilter', ["branchPattern", "pullRequest"], [BS.BranchesPopup.createParams('${buildForm.settingsId}'), ""]);
      </c:if>
      BS.MultilineProperties.updateVisible();

    </script>
  </td>
</tr>
