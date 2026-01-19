<%@include file="/include-internal.jsp"%>
<jsp:useBean id="usagesBean" type="jetbrains.buildServer.controllers.admin.projects.TemplateUsagesBean" scope="request"/>

<h2 class="noBorder">Build Configuration Template <admin:editTemplateLink templateId="${usagesBean.template.externalId}"><c:out value="${usagesBean.template.name}"/></admin:editTemplateLink></h2>

<c:if test="${usagesBean.enforcedSettingsUsagesNumber > 0}">
  <div class="usagesSection">
    <div>
      Used as enforced settings in <strong>${usagesBean.enforcedSettingsUsagesNumber}</strong> project<bs:s val="${usagesBean.enforcedSettingsUsagesNumber}"/>:
    </div>

    <c:forEach items="${usagesBean.enforcedSettingsUsages}" var="prj">
      <ul>
        <authz:authorize anyPermission="EDIT_PROJECT, VIEW_BUILD_CONFIGURATION_SETTINGS" projectId="${prj.projectId}">
          <jsp:attribute name="ifAccessGranted">
            <li><admin:editProjectLinkFull project="${prj}" contextProject="${currentProject}"/></li>
          </jsp:attribute>
          <jsp:attribute name="ifAccessDenied">
            <li><c:out value="${prj.fullName}"/></li>
        </jsp:attribute>
        </authz:authorize>
      </ul>
    </c:forEach>
  </div>
</c:if>


<c:if test="${usagesBean.defaultTemplateUsagesNumber > 0}">
  <div class="usagesSection">
    <div>
      Used as default in <strong>${usagesBean.defaultTemplateUsagesNumber}</strong> project<bs:s val="${usagesBean.defaultTemplateUsagesNumber}"/>:
    </div>

    <c:forEach items="${usagesBean.defaultTemplateUsages}" var="prj">
      <ul>
        <authz:authorize anyPermission="EDIT_PROJECT, VIEW_BUILD_CONFIGURATION_SETTINGS" projectId="${prj.projectId}">
          <jsp:attribute name="ifAccessGranted">
            <li><admin:editProjectLinkFull project="${prj}" contextProject="${currentProject}"/></li>
          </jsp:attribute>
          <jsp:attribute name="ifAccessDenied">
            <li><c:out value="${prj.fullName}"/></li>
        </jsp:attribute>
        </authz:authorize>
      </ul>
    </c:forEach>
  </div>
</c:if>

<c:if test="${usagesBean.buildTypesNumber > 0}">
  <div class="usagesSection">
    <div>
      Used in <strong>${usagesBean.buildTypesNumber}</strong> build configuration<bs:s val="${usagesBean.buildTypesNumber}"/><c:if test="${fn:length(usagesBean.dependingBuildTypes) < usagesBean.buildTypesNumber}"> (you do not have enough permissions to see all of them)</c:if>:
    </div>

    <c:if test="${not empty usagesBean.dependingBuildTypes}">
      <ul>
        <c:forEach items="${usagesBean.dependingBuildTypes}" var="bt">
          <authz:authorize allPermissions="EDIT_PROJECT" projectId="${bt.projectId}">
            <jsp:attribute name="ifAccessGranted">
              <c:set var="editLink"></c:set>
              <li><admin:editBuildTypeLinkFull buildType="${bt}"/></li>
            </jsp:attribute>
            <jsp:attribute name="ifAccessDenied">
              <li><c:out value="${bt.fullName}"/></li>
            </jsp:attribute>
          </authz:authorize>
        </c:forEach>
      </ul>
    </c:if>
  </div>

</c:if>
