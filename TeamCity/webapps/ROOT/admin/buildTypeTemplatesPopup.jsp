<%@include file="/include-internal.jsp"%>
<jsp:useBean id="templatesBean" type="jetbrains.buildServer.controllers.admin.projects.TemplateListBean" scope="request"/>
<div><strong>This build configuration is based on the following template<bs:s val="${templatesBean.numberOfTemplates}" />:</strong></div>
<ul class="menuList menuListWrappable">
<c:forEach items="${templatesBean.templates}" var="template">
  <authz:authorize allPermissions="VIEW_PROJECT" projectId="${template.projectId}">
    <jsp:attribute name="ifAccessGranted">
      <c:set var="editLink"><admin:editTemplateLink templateId="${template.externalId}" withoutLink="true"/></c:set>
      <l:li title="Edit template"><a href="${editLink}" title="Edit template"><c:out value="${template.fullName}"/></a></l:li>
    </jsp:attribute>
    <jsp:attribute name="ifAccessDenied">
      <li><c:out value="${template.fullName}"/></li>
    </jsp:attribute>
  </authz:authorize>
</c:forEach>
</ul>
