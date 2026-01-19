<%@ include file="/include-internal.jsp" %>
<%--@elvariable id="currentProject" type="jetbrains.buildServer.serverSide.SProject"--%>
<%--@elvariable id="trustedProject" type="jetbrains.buildServer.serverSide.SProject"--%>
<%--@elvariable id="usages" type="java.util.Collection<jetbrains.buildServer.controllers.admin.usage.TrustedDependenciesUsagesReport.RelatedDependency"--%>
<%--@elvariable id="usagesNum" type="java.lang.Integer"--%>

<div class="usagesSection">
  <c:choose>
    <c:when test="${not empty trustedProject}">
      <h2>Trusted dependency to project <c:out value="${trustedProject.name}"/></h2>
      <p>There are <c:out value="${usagesNum}"/> dependencies affected by this trusted dependency.</p>

      <c:if test="${usagesNum gt 0}">
        <table class="parametersTable">
          <tr>
            <th>
              Dependent
            </th>
            <th>
              Depends on
            </th>
            <th>
              Dependency type
            </th>
          </tr>
          <c:forEach items="${usages}" var="usage">
            <c:set var="dependsOn" value="${usage.dependOn}"/>
            <c:set var="dependent" value="${usage.dependent}"/>
            <c:set var="dependencyType" value="${usage.dependencyType}"/>

            <tr>
              <td>
                <c:set var="canEdit" value="${afn:permissionGrantedForBuildType(dependent, 'EDIT_PROJECT') and (not dependent.templateBased or dependent.templateAccessible)}"/>
                <c:choose>
                  <c:when test="${canEdit}">
                    <admin:editBuildTypeLinkFull buildType="${dependent}"/>
                  </c:when>
                  <c:otherwise>
                    <c:out value="${dependent.fullName}"/>
                  </c:otherwise>
                </c:choose>
              </td>
              <td>
                <c:set var="canEdit" value="${afn:permissionGrantedForBuildType(dependsOn, 'EDIT_PROJECT') and (not dependsOn.templateBased or dependsOn.templateAccessible)}"/>
                <c:choose>
                  <c:when test="${canEdit}">
                    <admin:editBuildTypeLinkFull buildType="${dependsOn}"/>
                  </c:when>
                  <c:otherwise>
                    <c:out value="${dependsOn.fullName}"/>
                  </c:otherwise>
                </c:choose>
              </td>
              <td>
                <c:out value="${fn:toLowerCase(dependencyType)}"/>
              </td>
            </tr>
          </c:forEach>
        </table>
      </c:if>
    </c:when>
    <c:otherwise>
      Project does not exist.
    </c:otherwise>
  </c:choose>
</div>



