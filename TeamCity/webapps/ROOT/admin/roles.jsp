<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="forms" tagdir="/WEB-INF/tags/forms"%>

<jsp:useBean id="rolesForm" type="jetbrains.buildServer.controllers.admin.roles.EditRolesForm" scope="request"/>
<jsp:useBean id="pageUrl" type="java.lang.String" scope="request"/>

<bs:refreshable containerId="rolesList" pageUrl="${pageUrl}">
<div class="rolesTable">
 <bs:messages key="rolesUpdated"/>

 <c:if test="${afn:permissionGrantedGlobally('MANAGE_ROLES')}">
   <forms:addButton onclick="BS.CreateRoleDialog.show(); return false">Create new role</forms:addButton>
   <br/><br/>
 </c:if>

<style>
  #rolesList .disabledPermission,
  .addPermissionsDialog .disabledPermission {
    color: grey;
  }

  #rolesList .disabledPermission:after,
  .addPermissionsDialog .disabledPermission:after {
    margin-left: 1.5em;
    content: "disabled on this server";
    font-style: italic;
  }
</style>

 <c:forEach items="${rolesForm.roles}" var="role">
   <a name="${role.id}"></a>
   <bs:messages key="roleUpdated${role.id}"/>
   <l:tableWithHighlighting id="role${role.id}" className="rolesTable">
     <tr class="role">
      <td><span class="roleName"><c:out value="${role.name}"/></span></td>
      <c:if test="${afn:permissionGrantedGlobally('MANAGE_ROLES')}">
          <td class="remove">
             <a href="#" onclick="BS.RolesForm.deleteRole('${role.id}'); return false">Delete</a>
          </td>
      </c:if>
     </tr>
     <c:forEach items="${role.includedRoles}" var="included">
      <tr>
        <td>includes <span class="roleName"><c:out value="${included.name}"/></span></td>
        <c:if test="${afn:permissionGrantedGlobally('MANAGE_ROLES')}">
         <td class="remove">
            <a href="#" onclick="BS.RolesForm.excludeIncludedRole('${role.id}', '${included.id}'); return false">Exclude</a>
         </td>
        </c:if>
      </tr>
     </c:forEach>
     <c:forEach items="${role.permissions}" var="permission">
         <tr>
           <td><c:out value="${permission.description}"/></td>
           <c:if test="${afn:permissionGrantedGlobally('MANAGE_ROLES')}">
             <td class="remove">
               <a href="#" onclick="BS.RolesForm.removePermission('${role.id}', '${permission.name}'); return false">Delete</a>
             </td>
           </c:if>
         </tr>
     </c:forEach>
     <c:forEach items="${role.disabledPermissions}" var="permission">
         <tr>
           <td class="disabledPermission"><c:out value="${permission.description}"/></td>
           <c:if test="${afn:permissionGrantedGlobally('MANAGE_ROLES')}">
             <td class="remove">
               <a href="#" onclick="BS.RolesForm.removePermission('${role.id}', '${permission.name}'); return false">Delete</a>
             </td>
           </c:if>
         </tr>
     </c:forEach>
   </l:tableWithHighlighting>
   <c:if test="${afn:permissionGrantedGlobally('MANAGE_ROLES')}">
     <p>
       <c:if test="${role.permissionsAvailable}">
         <forms:addButton onclick="BS.AddPermissionsDialog.show('${role.id}'); return false">Add permission</forms:addButton>
         &nbsp;
       </c:if>
       <c:if test="${role.rolesAvailable}">
         <forms:addButton onclick="BS.IncludeRoleDialog.show('${role.id}'); return false">Include role</forms:addButton>
       </c:if>
     </p>
   </c:if>
   <br/>
 </c:forEach>

<l:tableWithHighlighting id="role${rolesForm.administratorRole.id}" className="rolesTable">
  <tr class="role">
   <td><span class="roleName"><c:out value="${rolesForm.administratorRole.name}"/></span></td>
  </tr>
  <tr>
     <td>Includes all available permissions</td>
  </tr>
</l:tableWithHighlighting>

</div>
</bs:refreshable>

<c:if test="${afn:permissionGrantedGlobally('MANAGE_ROLES')}">
  <bs:refreshable containerId="addPermissionsDialogs" pageUrl="${pageUrl}">
    <admin:addPermissionsDialog rolesForm="${rolesForm}"/>
    <admin:includeRoleDialog rolesForm="${rolesForm}"/>
  </bs:refreshable>

  <c:url var="action" value="/admin/action.html"/>
  <bs:modalDialog formId="createRole" title="Create Role" action="${action}"
                  closeCommand="BS.CreateRoleDialog.close();" saveCommand="BS.CreateRoleDialog.save();">

    <label for="roleName" class="tableLabel" style="width: 6em;">Role name:</label>
    <forms:textField name="roleName" value="" className="longField"/>
    <span class="error" id="error_roleName" style="margin-left: 6em;"></span>

    <div class="popupSaveButtonsBlock">
      <forms:submit name="createRole" label="Create"/>
      <forms:cancel onclick="BS.CreateRoleDialog.close()"/>
      <forms:saving id="creatingRole"/>
    </div>
  </bs:modalDialog>
</c:if>
