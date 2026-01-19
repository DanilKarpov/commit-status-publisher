<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<jsp:useBean id="buildForm" type="jetbrains.buildServer.controllers.admin.projects.BuildTypeForm" scope="request"/>

<c:if test="${empty buildForm.buildRunnerBean.selectedRunType.deprecationReason}">
  <tr>
    <td colspan="2">
      <div class="attentionComment">
        <bs:buildStatusIcon type="red-sign" className="warningIcon"/>
        <c:choose>
          <c:when test="${buildForm.buildRunnerBean.selectedRunType.type == 'VSTest'}">
            <strong>VSTest.Console</strong> runner is not bundled with TeamCity anymore. You can download this runner from the <a href="https://confluence.jetbrains.com/display/TW/VSTest.Console+Runner" target="_blank" rel="noreferrer">plugin page</a>.
          </c:when>
          <c:otherwise>
            Build runner type "<strong><c:out value="${buildForm.buildRunnerBean.selectedRunType.type}"/></strong>" used by this build step is not loaded or is not installed anymore.
          </c:otherwise>
        </c:choose>
      </div>
    </td>
  </tr>
</c:if>
