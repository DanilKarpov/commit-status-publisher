<%@ include file="/include.jsp" %>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props" %>
<jsp:useBean id="propertiesBean" type="jetbrains.buildServer.controllers.BasePropertiesBean" scope="request"/>

<tr>
  <td colspan="2">
    <em>This trigger monitors VCS repository branches and triggers a personal build with detected changes.
      See the <bs:helpLink file='Branch+Remote+Run+Trigger'>Branch Remote Run Trigger</bs:helpLink> page for details.</em>
  </td>
</tr>
<c:choose>
  <c:when test="${noBranchSupports}">
    <tr>
      <td colspan="2">
        No supported types of VCS found. Supported VCS types:
        <c:forEach var="vcs" items="${supportedVcses}" varStatus="status"
            ><c:out value="${vcs}"/><c:if test="${not status.last}">, </c:if></c:forEach>.
      </td>
    </tr>
  </c:when>
  <c:otherwise>
    <l:settingsGroup title="Pattern of Branches to Monitor"/>
    <c:forEach var="vcs" items="${vcses}">
      <props:hiddenProperty name="branchy:${vcs.name}" value="pattern:${vcs.name}"/>
      <tr>
        <td><label for="pattern:${vcs.name}"><c:out value="${vcs.displayName}"/>:</label></td>
        <td>
          <props:textProperty name="pattern:${vcs.name}" style="width:25em;"/>
          <span class="error" id="error_pattern:${vcs.name}"></span>
        </td>
      </tr>
    </c:forEach>
    <tr>
      <c:if test="${fn:length(unsupported) > 0}">
      <td colspan="2">Not supported VCS types (won't be monitored for changes):
        <c:forEach var="vcs" items="${unsupported}" varStatus="status"
            ><c:out value="${vcs}"/><c:if test="${not status.last}">, </c:if></c:forEach>.
      </td>
      </c:if>
    </tr>
    <c:if test="${manyDvcsRoots}">
    <tr>
      <td colspan="2">
        <div class="attentionComment">
          <bs:buildStatusIcon type="red-sign" className="warningIcon"/>You have more than one VCS root with remote-run on branches support. In this case there are some limitations, please refer to the <bs:helpLink file='Branch+Remote+Run+Trigger'>documentation</bs:helpLink> for details.
        </div>
      </td>
    </tr>
    </c:if>
  </c:otherwise>
</c:choose>