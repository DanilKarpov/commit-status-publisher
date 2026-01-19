<%--
  Created by IntelliJ IDEA.
  User: sergeypak
  Date: 08/09/2017
  Time: 17:02
  To change this template use File | Settings | File Templates.
--%>
<%@include file="/include-internal.jsp" %>

<jsp:useBean id="profile" scope="request" type="jetbrains.buildServer.clouds.CloudProfile"/>
<jsp:useBean id="projectExtId" scope="request" type="java.lang.String"/>
<jsp:useBean id="showEditLink" scope="request" type="java.lang.Boolean"/>
<c:if test="${projectExtId != ''}">
  <authz:authorize allPermissions="MANAGE_AGENT_CLOUDS" projectId="${profile.projectId}">
    <c:url var="editUrl" value="/admin/editProject.html?projectId=${projectExtId}&tab=clouds&action=edit&profileId=${profile.profileId}&showEditor=true"/>
    <script>
      $j('li').each(function(){
        if ($j(this).text().indexOf('Cloud image:') == 0){
          // add link in agent details
          var editLinkData = '';
          <c:if test="${showEditLink}">
            editLinkData = ' (<a href="${editUrl}">Edit</a>)</li>';
          </c:if>
          $j(this).after('<li>Cloud profile: <strong><bs:escapeForJs forHTMLAttribute="true" text="${profile.profileName}"/></strong>' + editLinkData);
        }
      })
    </script>
  </authz:authorize>
</c:if>
