<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="currentProject" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>
<jsp:useBean id="cers" type="java.util.Collection<jetbrains.buildServer.ssl.TeamCityTrustedSslCertificate>" scope="request"/>

<style type="text/css">
  div.projectRoots {
    margin-left: 1em;
  }
  div.usagesCategory {
    font-weight: bold;
  }
</style>

<script type="text/javascript">
  BS.CertsDialog = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, OO.extend(BS.FileBrowse, {
    getContainer: function () {
      return $('certDialog');
    },

    selectAllowSync: function(projectId, value) {
      BS.ajaxRequest('<c:url value="/admin/sslCertActions.html"/>', {
        parameters: Object.toQueryString({action: 'selectAllowSync', projectId: projectId, value: value}),
        onComplete: function(transport) {
          window.location.reload();
        }
      });
    },

    deleteCert: function(projectId, alias) {
      if (confirm('Are you sure you want to delete this certificate?')) {
        BS.ajaxRequest('<c:url value="/admin/sslCertActions.html"/>', {
          parameters: Object.toQueryString({action: 'deleteSslCert', projectId: projectId, alias: alias}),
          onComplete: function(transport) {
            window.location.reload();
          }
        });
      }
    },

    createCert: function() {
      this.cleanFields();
      this.cleanErrors();
      this.showCentered();
    },

    cleanFields: function() {
      $j('#alias').val('');
      $j('#file\\:fileToUpload').val('');
      $j('#CertsDialogSubmit').attr('disabled', 'disabled');
    },

    changeFile: function() {
      var alias = $j("#alias").val();
      var file = $j("#file\\:fileToUpload").val();
      var cleanFile = file.substr(file.lastIndexOf("\\") + 1);
      if (cleanFile.lastIndexOf(".") != -1) {
        cleanFile = cleanFile.substr(0, cleanFile.lastIndexOf("."));
      }
      cleanFile = cleanFile.replace(/[^A-Za-z0-9_-]/gi, '');
      if (!this.valNotEmpty(alias)) {
        $j("#alias").val(cleanFile);
      }
      this.validateFill();
    },

    validateFill: function() {
      var alias = $j("#alias").val();
      var file = $j("#file\\:fileToUpload").val();
      var saveButton = $j('#CertsDialogSubmit');
      var error = $j("#nameError");
      var aliasOk = true;
      var fileOk = false;

      if (typeof file !== 'undefined' && file.length > 0) {
        fileOk = true;
      }

      if (this.valNotEmpty(alias)) {
        if (!this.valRegexOk(alias)) {
          aliasOk = false;
          error.text("Only alpha-numeric characters are allowed.").show();
        } else if (!this.uniqueName(alias)) {
          aliasOk = false;
          error.text("A certificate with such name already exists. Use a different name or delete the existing certificate.").show();
        } else if (alias.length > 250) {
          aliasOk = false;
          error.text("Max length is 250 characters.").show();
        }
      } else {
        aliasOk = false;
      }

      if (aliasOk) {
        error.hide();
        if (fileOk) {
          saveButton.prop('disabled', false);
          return;
        }
      }

      saveButton.attr('disabled', 'disabled');
    },

    uniqueName: function(alias) {
      var lower = alias.toLowerCase();
      return this.files.find(function(e) { return e.toLowerCase() === lower;}) === undefined;
    },

    valNotEmpty: function(value) {
      return typeof value !== 'undefined' && value.length > 0;
    },

    valRegexOk: function(value) {
      return /^[A-Za-z0-9_-]+$/i.test(value);
    },

    cleanErrors: function() {
      $("uploadError").innerHTML = '';
      $("nameError").innerHTML = '';
    },

    closeAndRefresh: function() {
      Form.enable($('certForm'));
      BS.CertsDialog.close();
      window.location.reload();
    }
  })));
</script>

<div class="section noMargin">
  <h2 class="noBorder">SSL / HTTPS Certificates</h2>
  <bs:smallNote>
    The list of custom certificates which TeamCity considers trusted when establishing SSL connections.
    <br/>
    Only upload a certificate which comes from a reliable, trustworthy source. <bs:help file="Uploading+SSL+Certificates"/>
  </bs:smallNote>

  <c:set var="cameFromUrl" value="${param['cameFromUrl']}"/>
  <bs:refreshable containerId="cers" pageUrl="${pageUrl}">
    <bs:messages key="sslCertUploaded"/>
    <bs:messages key="sslCertDeleted"/>
    <bs:messages key="sslAllowSync"/>

    <c:set var="canUpload" value="${afn:permissionGrantedGlobally('MANAGE_CUSTOM_SSL_CERTIFICATES')}"/>

    <c:if test="${canUpload}">
      <forms:addButton id="createNewCert" onclick="BS.CertsDialog.createCert(); return false">Upload certificate</forms:addButton>
    </c:if>

    <br/>

    <c:if test="${not empty cers}">
      <table class="parametersTable" style="width: 100%">
        <tr>
          <th colspan="2">Name</th>
        </tr>
        <c:forEach var="cer" items="${cers}">
          <tr>
            <td class="name beforeActions">
              <c:out value="${cer.name}"/>
            </td>
            <c:if test="${canUpload}">
              <td class="edit">
                <a href="#" onclick="BS.CertsDialog.deleteCert('${currentProject.externalId}', '${cer.name}')">Delete</a>
              </td>
            </c:if>
          </tr>
        </c:forEach>
      </table>
    </c:if>
  </bs:refreshable>
</div>

<c:url var="action" value="/admin/sslCerts.html"/>
<bs:dialog dialogId="certDialog"
           dialogClass="certDialog uploadDialog"
           title="Upload Certificate"
           closeCommand="BS.CertsDialog.close()">
  <forms:multipartForm id="certForm" action="${action}" targetIframe="hidden-iframe" onsubmit="return BS.CertsDialog.validate();">
    <table class="runnerFormTable">
      <tr>
        <th><label for="alias">Name:</label><l:star/></th>
        <td>
          <input type="text" id="alias" name="alias" value="" class="mediumField" onKeyup="BS.CertsDialog.validateFill()"/>
          <span id="nameError" class="error hidden" style="margin: 0.2em 0 0 0.6em"></span>
          <%--<span class="smallNote" style="margin-left: 4px">Name should contain alpha-numeric characters only.</span>--%>
        </td>
      </tr>
      <tr>
        <th><label for="file:fileToUpload">Certificate File:</label><l:star/></th>
        <td>
          <forms:file name="fileToUpload" size="28" onchange="BS.CertsDialog.changeFile()"/>
          <div style="margin-left: 0.6em"><bs:smallNote>Supported formats: PEM, DER and PKCS#7.</bs:smallNote></div>
          <span id="uploadError" class="error hidden"></span>
        </td>
      </tr>
    </table>
    <input type="hidden" name="action" value="createCert"/>
    <input type="hidden" name="projectId" value="${currentProject.externalId}"/>
    <div class="popupSaveButtonsBlock">
      <forms:submit id="CertsDialogSubmit" label="Save"/>
      <forms:cancel onclick="BS.CertsDialog.close()"/>
    </div>
  </forms:multipartForm>
</bs:dialog>

<script type="text/javascript">
  BS.CertsDialog.setFiles([<c:forEach var="cer" items="${cers}">'${cer.name}',</c:forEach>]);
  BS.CertsDialog.prepareFileUpload();
</script>
