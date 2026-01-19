<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="util" uri="/WEB-INF/functions/util" %>
<%@ include file="/include-internal.jsp"%>
<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>
<jsp:useBean id="oauthProvider" type="jetbrains.buildServer.serverSide.oauth.OAuthConnectionDescriptor" scope="request"/>
<jsp:useBean id="oauthUsername" type="java.lang.String" scope="request"/>
<c:url value='/admin/createObjectFromUrl.html' var="createFromUrl"/>
<form id="createFromUrlForm" action="${createFromUrl}" method="post">
  <input type="hidden" name="init" value="1"/>
  <input type="hidden" name="url"/>
  <input type="hidden" name="parentId" value=""/>
  <input type="hidden" name="username" value="${oauthUsername}"/>
  <input type="hidden" name="objectType" value=""/>
  <input type="hidden" name="oauthProviderId" value="${oauthProvider.id}"/>
  <input type="hidden" name="cameFromUrl" value=""/>
  <input type="hidden" name="credentialsMandatory" value=""/>
  <input type="hidden" name="tokenType" value=""/>
  <input type="hidden" name="tokenId" value=""/>
</form>
<script type="text/javascript">
  BS.CreateFromUrlForm = OO.extend(BS.AbstractPasswordForm, {
    formElement: function() {
      return $('createFromUrlForm');
    },

    submit: function() {
      var parentIdSel = $('parentId');
      if (parentIdSel) {
        if (parentIdSel.options) {
          // parent project selector is shown
          this.formElement().parentId.value = parentIdSel.options[parentIdSel.selectedIndex].value;
        } else {
          // parent project selector is hidden
          this.formElement().parentId.value = parentIdSel.value;
        }
      }
      var cameFromUrl = this.formElement().cameFromUrl.value;
      BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
        parentId: function(elem) {
          this._redirectOnError();
        },

        url: function(elem) {
          this._redirectOnError();
        },

        password: function(elem) {
          this._redirectOnError();
        },

        username: function(elem) {
          this._redirectOnError();
        },

        _redirectOnError: function() {
          document.location.href = '${createFromUrl}?parentId=${project.externalId}&cameFromUrl=' + encodeURIComponent(cameFromUrl);
        },

        onSuccessfulSave : function(responseXML) {
          BS.XMLResponse.processRedirect(responseXML);
        }
      }));

      return false;
    }
  });

  $('createFromUrlForm').cameFromUrl.value = document.location.href.replace(/cameFromUrl=.*/, '');;
</script>
