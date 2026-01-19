<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props" %>
<%@ taglib prefix="ring" tagdir="/WEB-INF/tags/ring" %>
<jsp:useBean id="buildForm" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm" scope="request"/>
<jsp:useBean id="propertiesBean" type="jetbrains.buildServer.controllers.admin.projects.EditableUserDefinedParametersBean" scope="request"/>

<c:url value="/admin/editBuildParams.html?id=${buildForm.settingsId}" var="inputParamsUrl"/>
<c:url value="/admin/editOutputParams.html?id=${buildForm.settingsId}" var="outputParamsUrl"/>
<admin:editBuildTypePage selectedStep="buildParams">
  <jsp:attribute name="head_include">
    <bs:linkCSS>
      /css/settingsTable.css
      /css/admin/editUserParams.css
    </bs:linkCSS>
  </jsp:attribute>
  <jsp:attribute name="before_body_include">
    <div class="buildTypeSubTabs">
      <ring:buttonGroup className="ring-button-group-buttonGroup">
        <a class="ring-button-button ring-button-block  ring-button-heightM ring-button-active" href="${inputParamsUrl}">Input Parameters</a>
        <a class="ring-button-button ring-button-block  ring-button-heightM" href="${outputParamsUrl}">Output Parameters</a>
      </ring:buttonGroup>
    </div>
  </jsp:attribute>
  <jsp:attribute name="body_include">

    <div class="section noCaption">
      <bs:smallNote>
      Input parameters are used to customize behavior of the build steps or to parametrize the build to allow running it with different values of the same parameter.
      </bs:smallNote>

      <admin:userDefinedParameters userParametersBean="${propertiesBean}" parametersActionUrl="${inputParamsUrl}" readOnly="${buildForm.readOnly}"
                                   alwaysShowBuildParameters="${not buildForm.compositeBuild}" editableObjectId="settingsId=${buildForm.settingsId}"
                                   projectId="${buildForm.project.externalId}" buildTypeId="${buildForm.externalId}"/>
    </div>

    <script type="text/javascript">
      (function($) {
        $(document).ready(function() {
          if (document.location.hash.indexOf('edit_') != -1) {
            var selector = document.location.hash;
            $(selector).triggerHandler("click");
            document.location.hash = "";
          }
        });
      }(jQuery));
    </script>
  </jsp:attribute>
</admin:editBuildTypePage>
