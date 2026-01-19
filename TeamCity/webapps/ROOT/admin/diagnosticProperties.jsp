<%@include file="/include-internal.jsp" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>
<jsp:useBean id="propertiesBean" scope="request" type="jetbrains.buildServer.diagnostic.web.DiagnosticPropertiesExtension.PropertiesBean"/>

<table class="runnerFormTable" id="internalProperties">
  <c:set var="ownPropsTitle" value="Internal properties"/>
  <c:set var="parentPropsTitle" value="Internal properties"/>

  <c:if test="${propertiesBean.nodeHasOwnProperties}">
    <c:set var="ownPropsTitle" value="Current node internal properties"/>
    <c:set var="parentPropsTitle" value="Common internal properties"/>
    <tr class="groupingTitle">
      <td>${ownPropsTitle}: <code>${propertiesBean.fullPathToPropertiesFile}</code></td>
    </tr>
    <tr>
      <td class="values">
        <admin:_propertiesList properties="${propertiesBean.ownProperties}"/>
        <c:if test="${propertiesBean.canEditOwnProperties}">
          <c:url var="url" value="${propertiesBean.editOwnPropertiesURL}"/>
          <div style="margin-top: 0.5em">
            <a <c:if test="${not propertiesBean.internalPropertiesAvailable and propertiesBean.canModifyInternalProperties}">class="doCreateFile"</c:if> href="${url}"><i
                class="icon-pencil"></i> Edit properties &raquo;</a>
          </div>
        </c:if>
      </td>
    </tr>
  </c:if>

  <tr class="groupingTitle">
    <td>${parentPropsTitle}: <code>${propertiesBean.fullPathToParentPropertiesFile}</code></td>
  </tr>
  <tr>
    <td class="values">
      <admin:_propertiesList properties="${propertiesBean.parentProperties}"/>
      <c:if test="${propertiesBean.canEditParentProperties}">
        <c:url var="url" value="${propertiesBean.editParentPropertiesURL}"/>
        <div style="margin-top: 0.5em">
          <a <c:if test="${not propertiesBean.parentInternalPropertiesAvailable}">class="doCreateFile doCreateFileMain"</c:if> href="${url}"><i
              class="icon-pencil"></i> Edit properties &raquo;</a>
        </div>
      </c:if>
    </td>
  </tr>

  <tr class="groupingTitle">
    <td>Java system properties</td>
  </tr>
  <tr>
    <td class="noBorder values">
      <admin:_propertiesList properties="${propertiesBean.relatedSystemProperties}"/>
      <div><a href="#" id="otherPropToggle">Show all properties</a></div>
      <admin:_propertiesList properties="${propertiesBean.otherSystemProperties}"
                             style="display: none"
                             id="otherProperties"/>
    </td>
  </tr>
</table>

<script type="text/javascript">
  $j(function () {
    var $doCreateFile = $j(".doCreateFile");
    if ($doCreateFile.length > 0) {
      var url = $doCreateFile.attr("href");
      var mainFlag = $doCreateFile.hasClass("doCreateFileMain") ? "?main=true" : "";
      $doCreateFile.attr("href", "#").on("click", function () {
        BS.ajaxRequest(window['base_uri'] + '/admin/ajax/internalProperties.html' + mainFlag, {
          onComplete: function (transport) {
            if (transport.responseXML && transport.responseXML.firstChild) {
              var response = transport.responseXML.firstChild;
              var error = response.getElementsByTagName("error")[0];
              if (error) {
                alert("Cannot create internal.properties: " + error.firstChild.data);
              } else {
                window.location = url;
              }
            }
            return false;
          }
        });
      });
    }

    $j("#otherPropToggle").click(function () {
      $j("#otherProperties").toggle();
      $j(this).hide();
      return false;
    });
  });
</script>
