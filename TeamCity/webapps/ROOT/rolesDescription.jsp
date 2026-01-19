<%@ include file="/include-internal.jsp"%>
<jsp:useBean id="rolesList" type="java.util.Collection" scope="request"/>
<c:set var="title" value="Available Roles"/>
<bs:externalPage>
  <jsp:attribute name="page_title">${title}</jsp:attribute>
  <jsp:attribute name="head_include">
    <bs:linkCSS>
      /css/rolesDescription.css
    </bs:linkCSS>
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <div class="container">
    <table class="settings rolesDescription">
      <tr style="background-color: var(--ring-secondary-background-color, #f7f9fa);">
        <th class="name role">Role</th>
        <th class="name permissions">Permissions</th>
      </tr>
      <c:forEach items="${rolesList}" var="roleBean">
        <bs:rolePermissions role="${roleBean}"/>
      </c:forEach>
    </table>
    </div>
  </jsp:attribute>
</bs:externalPage>
